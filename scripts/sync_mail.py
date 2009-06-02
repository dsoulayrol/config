#!/usr/bin/env python
# sync_mail.py, a script to fetch and store mails.
# Copyright (C) 2009  David Soulayrol <david.soulayrol@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
This script provides a clean integration of multiple tools to handle
mail. It is designed to fit well in my own configuration, which is:

- Mutt as the MUA and Procmail as the MDA.
- My Imap account is duplicated on my hard drive, which provides me
    a full backup of my mail, which is also available while offline.
- I have one POP account in my office.

The script logically relies on isync to synchronise IMAP accounts, and
procmail to distribute new mail. It reads its configuration from
Mutt. POP fetching and glue is written using Python standard library.

The script should be run with at least one --imap or --pop argument to
provide mail sources since the information cannot be found in Mutt -
this one being used as a simple MUA. The --user option can be used to
override the user name, which can be useful if the environment doesn't
have the USER or LOGNAME variables set.

Usage: sync_mail.py [--user login]
                    [--imap user:pass@server{[!]box, ...}]
                    [--pop user:pass@server]
"""

from __future__ import with_statement # This isn't required in Python 2.6

import contextlib
import errno
import logging
import mailbox
import os
import poplib
import re
import subprocess
import sys
import time
import tempfile

try:
    import dbus
except ImportError:
    pass


__version__ = '20090529'

ISYNC_CONF_HEADER_PATTERN = """# -*- Generated by sync_mail.py -*-
#
# DO NOT EDIT!
#  Anyway, a new file is regenerated at each invocation. :)


# Global configuration section
#   Values here are used as defaults for any following Channel section that
#   doesn't specify them.
Expunge None
Create Both

# Local repository
MaildirStore Local
Path %s
Trash trash

"""

ISYNC_CONF_ACCOUNT_PATTERN = """# IMAP account
IMAPAccount %s
Host %s
User %s
Pass %s
RequireSSL no

IMAPStore %s
Account %s

"""

ISYNC_CONF_CHANNEL_PATTERN = """Channel %s
Master :%s:%s
Slave :Local:%s
Expunge Both

"""

FETCHMAIL_CONF_HEADER_PATTERN = """# -*- Generated by sync_mail.py -*-
#
# DO NOT EDIT!
#  Anyway, a new file is regenerated at each invocation. :)

set no bouncemail
set no spambounce
set properties ""

"""

FETCHMAIL_CONF_ACCOUNT_PATTERN = """
poll %s with proto POP3
       user '%s' there with password '%s' is '%s' here
       mda "/usr/bin/procmail"
       fetchall
"""


class LockError(Exception):
    """Exception raised on lock failure."""
    pass


def check_connection():
    proc = subprocess.Popen(
        ['ping', '-q', '-c1', 'google.com'],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc.wait()
    return proc.returncode == 0


def create_logger(name):
    pattern = '%(name)18s::%(lineno)-6s%(levelname)-10s%(message)s'
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(pattern))
    logger.addHandler(handler)
    return logger


@contextlib.contextmanager
def flock(path):
    """A simple filelock implementation, using python context manager.

    Adapted from the nice snippet found on
    http://code.activestate.com/recipes/576572/
    """
    while True:
        try:
            fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_RDWR)
        except OSError, e:
            if e.errno != errno.EEXIST:
                raise
            else:
                raise LockError
        else:
            break
    try:
        yield fd
    finally:
        os.unlink(path)


class Server(object):
    """Server connection information for synchronisation.
    """
    def __init__(self, match_object):
        self._name = match_object.group('server')
        self._user = match_object.group('user')
        self._pass = match_object.group('pass')

    def __repr__(self):
        return self._user + '@' + self._name

    def __str__(self):
        return self.__repr__()

    def _get_name(self):
        return self._name

    def _get_domain(self):
        return self._name.split('.')[-2].capitalize()

    def _get_user(self):
        return self._user

    def _get_pass(self):
        return self._pass

    name = property(_get_name)
    domain = property(_get_domain)
    user = property(_get_user)
    passwd = property(_get_pass)


class IMAPServer(Server):
    pass


class POP3Server(Server):
    pass


class MailboxOptions(object):
    def __init__(self, server, box_name):
        self._server = server
        self._mailbox = box_name

    def __repr__(self):
        return repr(self._server) + '/' + self._mailbox

    def __str__(self):
        return self.__repr__()

    def _get_server(self):
        return self._server

    def _get_mailbox(self):
        return self._mailbox

    server = property(_get_server)
    mailbox = property(_get_mailbox)


class MailboxStats(object):
    def __init__(self, path, name):
        self._name = name
        self._path = path
        self._new = 0
        self._unread = 0

    def __repr__(self):
        return '[M:' + self._name + ']'

    def __str__(self):
        return self.__repr__()

    def _get_name(self):
        return self._name

    def _get_path(self):
        return self._path

    def _get_full_path(self):
        return os.path.join(self._path, self._name)

    def _get_new(self):
        return self._new

    def _set_new(self, value):
        self._new = value

    def _get_unread(self):
        return self._unread

    def _set_unread(self, value):
        self._unread = value

    name = property(_get_name)
    path = property(_get_path)
    full_path = property(_get_full_path)
    new = property(_get_new, _set_new)
    unread = property(_get_unread, _set_unread)


class MaildirWrapper(mailbox.Maildir):
    def __init__(self, options, stats):
        mailbox.Maildir.__init__(self, stats.full_path, factory=None, create=False)
        self.options = options
        self.stats = stats

    def __repr__(self):
        return '[Maildir:' + repr(self.stats) + ']'

    def __str__(self):
        return self.__repr__()

    def add(self, message):
        mailbox.Maildir.add(self, message)
        self.stats.new += 1

    def is_message_read(self, msg):
        return msg.get_flags().find('S') >= 0

    def is_message_sorted(self, msg):
        return msg.get_subdir() != 'new'


class MboxWrapper(mailbox.mbox):
    def __init__(self, options, stats):
        mailbox.mbox.__init__(self, stats.full_path, create=False)
        self.options = options
        self.stats = stats

    def __repr__(self):
        return '[MBox:' + repr(self.stats) + ']'

    def __str__(self):
        return self.__repr__()

    def add(self, message):
        mailbox.mbox.add(self, message)
        self.stats.new += 1

    def is_message_read(self, msg):
        return msg.get_flags().find('R') >= 0

    def is_message_sorted(self, msg):
        return not self.is_message_read(msg)


class Account(object):
    def __init__(self, filename, folder, mailbox_options):
        self._logger = create_logger(self.__class__.__name__)
        self._file = filename
        self._folder = folder
        self._mailboxes = []
        self._parse(mailbox_options)

    def __repr__(self):
        return '[A:' + repr(self._mailboxes) + ']'

    def __str__(self):
        return self.__repr__()

    def _get_mailboxes(self):
        return self._mailboxes

    def _parse(self, mailbox_options):
        with open(self._file) as f:
            self._logger.info('parsing %s' % self._file)
            for line in f:
                if line.startswith('mailboxes'):
                    self._parse_mailbox(line[10:-1], mailbox_options)

    def _parse_mailbox(self, mb_name, mailbox_options):
        if mb_name.startswith('"'):
            mb_name = mb_name[1:-1]

        if mb_name.startswith('$folder/'):
            mb_name = mb_name[8:]
        elif mb_name[0] in ['=', '+']:
            mb_name = mb_name[1:]
        else:
            self._logger.warn('unsupported mailbox %s' % mb_name)
            return

        try:
            mb_options = mailbox_options.setdefault(mb_name, None)
            mb_stats = MailboxStats(self._folder, mb_name)
            self._mailboxes.append(
                self._generate_mailbox(
                    self._folder, mb_name, mb_options, mb_stats))
            self._logger.debug('created %s %s %s' % (mb_name, mb_options, mb_stats))
        except mailbox.NoSuchMailboxError:
            self._logger.error('non existent mailbox %s' % mb_name)

    def _generate_mailbox(self, folder, name, options, stats):
        path = os.path.join(folder, name)
        if os.path.isdir(path):
            return MaildirWrapper(options, stats)
        elif os.path.isfile(path):
            return MboxWrapper(options, stats)
        else:
            raise mailbox.NoSuchMailboxError

    mailboxes = property(_get_mailboxes)


class Configuration(object):
    def __init__(self):
        self._logger = create_logger(self.__class__.__name__)
        self._user = self._guess_user()
        self._accounts = []
        self._root_path = os.path.join('/home', self._user)
        self._folder = os.path.join(self._root_path, 'Mail')
        self._timestamp = time.time()

    def parse(self):
        """Mutt configuration parser.

        This parser looks for folder settings in ~login/.mutt/muttrc
        and mailboxes setting in ~login/.mutt/accounts/*. It is not
        smart enough to distinguish hooks and it will happily
        aggregate any matching lines.
        """
        self._parse_muttrc(os.path.join(self._root_path, '.mutt/muttrc'))
        self._parse_accounts(os.path.join(self._root_path, '.mutt/accounts'))

    def get_accounts_by_server(self):
        """Reorder known mailboxes by synchronisation servers.
        """
        sorted_accounts = {}
        for account in self._accounts:
            for box in account.mailboxes:
                if box.options:
                    sorted_accounts.setdefault(
                        box.options.server, []).append(box)
        return sorted_accounts

    def get_mailbox(self, name):
        for account in self._accounts:
            for box in account.mailboxes:
                if box.stats.name == name:
                    return box

    def _get_accounts(self):
        return self._accounts

    def _get_folder(self):
        return self._folder

    def _get_timestamp(self):
        return self._timestamp

    def _get_user(self):
        return self._user

    def _guess_user(self):
        """Search for the user name.

        User name is determined using, in this order, the --user
        command line argument, the USER or LOGNAME environment
        variable.
        """
        for arg in sys.argv:
            if arg.startswith('--user='):
                user = arg[7:]

        if not '_user' in self.__dict__:
            if os.environ.has_key('USER'):
                user = os.environ['USER']
            elif os.environ.has_key('LOGNAME'):
                user = os.environ['LOGNAME']

        if not len(user):
            self._logger.error('no user name.')
            raise ValueError('no user name')
        return user

    def _get_mailbox_info(self):
        sync_options = {}
        pattern = re.compile(
            '^(?P<user>\w+):(?P<pass>\w+)@(?P<server>[\.\w]+){(?P<boxes>[\!\w,]+)}')
        for arg in (e for e in sys.argv if e.startswith('--imap=')):
            m = pattern.match(arg[7:])
            if m:
                self._logger.info(
                    'parsing imap settings for %s' % m.group('server'))
                server = IMAPServer(m)
                for box_name in m.group('boxes').split(','):
                    if box_name.startswith('!'):
                        box_name = box_name[1:]
                    options = MailboxOptions(server, box_name)
                    box_localname = '.'.join([options.server.domain.lower(), box_name.lower()])
                    sync_options[box_localname] = options
                    self._logger.debug('  added %s' % options)

        pattern = re.compile(
            '^(?P<user>[\.@\w]+):(?P<pass>\w+)@(?P<server>[\.\w]+)')
        for arg in (e for e in sys.argv if e.startswith('--pop=')):
            m = pattern.match(arg[6:])
            if m:
                self._logger.info(
                    'parsing pop3 settings for %s' % m.group('server'))
                server = POP3Server(m)
                # TODO: Should use Mutt configured spool here.
                options = MailboxOptions(server, 'inbox')
                sync_options['inbox'] = options
                self._logger.debug('  added %s' % options)

        return sync_options

    def _parse_muttrc(self, path):
        with open(path) as f:
            self._logger.info('parsing %s' % path)
            pattern = re.compile(
                '^set folder\s*=\s*\"?(?P<value>~?[/\w]+)\"?')
            for line in f:
                m = pattern.match(line)
                if m:
                    self._folder = m.group('value')
                    self._folder = self._folder.replace('~', self._root_path)
                    self._logger.debug('folder set to %s' % self._folder)
                    return

    def _parse_accounts(self, path):
        mailbox_options = self._get_mailbox_info()
        for f in os.listdir(path):
            if f.endswith('~'):
                self._logger.debug('ignore emacs backup %s' % f)
                continue
            self._accounts.append(
                Account(os.path.join(path, f), self._folder, mailbox_options))

    accounts = property(_get_accounts)
    folder = property(_get_folder)
    timestamp = property(_get_timestamp)
    user = property(_get_user)


class IMAPSynchroniser(object):
    """A simple wrapper around isync.

    The IMAPSynchroniser is able to build a isync configuration file on
    the fly and execute it. Configuration file is built using the
    --imap arguments to the program. There can be any of
    them. Configuration is stored in a temporary file, so an existing
    configuration will be safe.
    """
    def __init__(self, conf):
        self._logger = create_logger(self.__class__.__name__)
        self._conf = conf
        self._isync_conf = self._build_configuration()

    def run(self):
        self._logger.info('synchronising boxes ...')
        conf_filename = self._flush_configuration()
        proc = subprocess.Popen(
            ['mbsync', '-c', conf_filename, '-a'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        status_re = re.compile(
            '^Selecting (?P<side>\w+) (?P<name>.+)\.\.\. (?P<msg>\d+) messages, (?P<new>\d+) recent')

        try:
            current_pair = {}
            line = proc.stdout.readline()
            while line != '':
                self._logger.debug('  (isync: ' + line[:-1] + ')')
                m = status_re.match(line)
                if m:
                    current_pair[m.group('side')] = (
                        m.group('name'), m.group('msg'), m.group('new'))
                if len(current_pair) == 2:
                    self._update_status(current_pair)
                    current_pair = {}
                line = proc.stdout.readline()
            proc.wait()
        finally:
            os.unlink(conf_filename)

    def _build_configuration(self):
        """Parse imap arguments on the command line to create the configuration.

        The configuration is built with following prerequisites in
        mind.

        The local mail image is named after the domain name of
        the server and the lowered mailbox. For example,
        imap.gmail.com/INBOX is mapped to gmail.inbox.

        The local store path is determined using the mutt
        configuration. Currently, the folder input is used.

        Channels are named after the server and the mailbox name.

        The builder does not support SSL.
        """
        # Trailing slash is very important in Path!
        root_path = self._conf.folder
        if not root_path.endswith('/'): root_path += '/'
        conf = ISYNC_CONF_HEADER_PATTERN % root_path

        for server, boxes in self._conf.get_accounts_by_server().items():
            if isinstance(server, IMAPServer):
                conf += ISYNC_CONF_ACCOUNT_PATTERN % (
                    server.domain, server.name, server.user, server.passwd,
                    server.domain, server.domain)
                for box in boxes:
                    channel = '.'.join([server.domain, box.options.mailbox.capitalize()])
                    conf += ISYNC_CONF_CHANNEL_PATTERN % (
                        channel, server.domain, box.options.mailbox, channel.lower())
        return conf

    def _flush_configuration(self):
        fd, name = tempfile.mkstemp(prefix='isync.')
        os.write(fd, self._isync_conf)
        os.close(fd)
        self._logger.debug('flushed isync configuration into %s' % name)
        return name

    def _update_status(self, pair):
        server = pair['master']
        local = pair['slave']
        box = self._conf.get_mailbox(local[0])
        box.stats.new += int(server[2])
        self._logger.info('Synchronising %s with %s (%s new messages)' % (
                local[0], server[0], server[2]))


class POPFetcher(object):
    """
    """
    def __init__(self, conf):
        self._logger = create_logger(self.__class__.__name__)
        self._conf = conf

    def run(self):
        self._logger.info('fetching pop accounts ...')
        for server, boxes in self._conf.get_accounts_by_server().items():
            if isinstance(server, POP3Server):
                self._logger.info('  fetching from %s' % server.name)
                ctl = poplib.POP3(server.name)
                ctl.user(server.user)
                ctl.pass_(server.passwd)

                # Only support only one box here. Should be the spool.
                box = boxes[0]
                box.lock()
                try:
                    for i in range(1, len(ctl.list()[1]) + 1):
                        message = '\r\n'.join(ctl.retr(i)[1])
                        self._conf.get_mailbox('inbox').add(message)
                        self._conf.get_mailbox('inbox').stats
                        self._logger.debug('  fetched message %d' % (i))
                        ctl.dele(i)
                finally:
                    ctl.quit()


class MailHandler(object):
    """A wrapper around procmail and companion tools."""
    # TODO: ensure that already sorted mail do not get resorted. Use a timestamp.
    def __init__(self, conf):
        self._logger = create_logger(self.__class__.__name__)
        self._conf = conf
        self._log = os.path.join('/tmp', 'procmail.' + str(conf.timestamp))

    def cleanup(self):
        os.unlink(self._log)

    def sort(self):
        self._logger.info('sorting new mail ...')

        # Parse the whole mailbox to sort and get stats as well. Does
        # this take too much of a hammer to hit a fly ? (and is this
        # french idiom correctly translated) :)
        for account in self._conf.accounts:
            for box in (b for b in account.mailboxes if b.stats.new):
                box.lock()
                self._logger.info('sorting %s ...' % box)
                for key, msg in box.iteritems():
                    if not box.is_message_sorted(msg):
                        self._sort(box, key, msg)
                box.unlock()

    def notify(self):
        """Notify the user using dbus.

        Note that if this script must be run by cron, it does not have
        any access to the variable environment which holds the DBus
        session address (DBUS_SESSION_BUS_ADDRESS). In such a case, it
        can be useful to execute a short script on session startup to
        store this information so it can be sourced in the cron job.

        Here is a script which would do the trick.

        #!/bin/sh

        # Export the dbus session address on startup so it can be used by cron
        #  (see http://earlruby.org/2008/08/update-pidgin-status-using-cron/)
        FILE=$HOME/.config/dbus_session

        touch $FILE
        chmod 600 $FILE
        env | grep DBUS_SESSION_BUS_ADDRESS > $FILE
        echo 'export DBUS_SESSION_BUS_ADDRESS' >> $FILE

        And here is a cron job sample, which calls this script every
        five minutes.

        */5 * * * * source ~/.config/dbus_session; ~/bin/sync_mail.py > ~/mail.log
        """
        self._logger.info('sending notification ...')

        if not dbus:
            self._logger.warn('dbus module is not installed')
            return

        if not os.environ.has_key('DBUS_SESSION_BUS_ADDRESS'):
            self._logger.warn('DBus session not available')
            return

        try:
            bus = dbus.SessionBus()
        except dbus.exceptions.DBusException:
            self._logger.warn('could not connect to dbus')
            return

        stats = self._count()

        try:
            self._notify_mail_app(bus, stats)
            self._logger.info('notification sent to mail app')
        except dbus.exceptions.DBusException:
            self._logger.warn('delivery to mail app failed')
            self._notify_desktop(bus, stats)
            self._logger.info('notification sent to desktop')

    def _notify_mail_app(self, bus, stats):
        obj = bus.get_object('net.soulayrol.MailNotifier',
                             '/net/soulayrol/MailNotifier')
        m = obj.get_dbus_method('notify', 'net.soulayrol.MailNotifier')
        m(stats)

    def _notify_desktop(self, bus, stats):
        message = ''
        for box, counts in stats.iteritems():
            if counts[0] > 0:
                message += '%d new messages in %s. %s old. Total: %s\n' % (
                    counts[0], box, counts[1], counts[2])

        if message:
            obj = bus.get_object('org.freedesktop.Notifications',
                                 '/org/freedesktop/Notifications')
            itf = dbus.Interface(obj, 'org.freedesktop.Notifications')
            itf.Notify('sync_mail.py', 0, '', 'New Mail!', message, [], {}, -1)

    def _count(self):
        """Count the sorted messages.

        Using the procmail output is far quicker than to iterate over
        messages using the python API to check what messages are read.
        """
        # TODO: there should be a system of aliases to associate
        # outputs from procmail to configured mailboxes. For example,
        # in the case of script pipes.
        proc = subprocess.Popen(
            ['mailstat', '-klmt', self._log],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        line_re = re.compile('^\s+\d+\s+\d+\s+(?P<nb>\d+) (?P<target>.+)')

        stats = {}
        line = proc.stdout.readline()
        while line != '':
            self._logger.debug('  (mailstat: ' + line[:-1] + ')')
            m = line_re.match(line)
            if m:
                box = m.group('target')
                if box.endswith('/'):
                    box = box[:-1]
                if self._conf.get_mailbox(box):
                    stats[box] = (int(m.group('nb')), 0, 0)
            line = proc.stdout.readline()
        proc.wait()
        return stats

    def _sort(self, box, key, msg):
        proc = subprocess.Popen(
            ['procmail', '-a', self._log],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        proc.communicate(msg.as_string())
        if proc.returncode == 0:
            self._logger.info(
                'sorted %s' % msg.get('Subject', '<undefined subject>'))
            box.discard(key)
        else:
            self._logger.info(
                'requeued %s !' % msg.get('Subject', '<undefined subject>'))


# Main functions

def start_sync():
    # if not check_connection():
    #     logger.error('no available connection.')
    #     sys.exit(1)

    try:
        # Install lock.
        with flock(os.path.join(os.environ['HOME'], '.sync_mail.lock')):

            # Read the Mutt configuration to get a single configuration source.
            config = Configuration()
            config.parse()

            # Synchronize IMAP accounts.
            IMAPSynchroniser(config).run()

            # Fetch mail from distant POP accounts.
            POPFetcher(config).run()

            # Handle incoming mail and notify the user.
            mail_handler = MailHandler(config)
            mail_handler.sort()
            mail_handler.notify()
            #mail_handler.cleanup()

    except LockError:
        sys.exit(2)

if __name__ == '__main__':
    start_sync()
