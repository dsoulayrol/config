#!/usr/bin/env python

"""
Usage: sync_mail.py [login]
"""

from __future__ import with_statement # This isn't required in Python 2.6

import logging
import os
import re
import subprocess
import sys
import shutil # temporary


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


class MailBox(object):
    def __init__(self, folder, name):
        self._name = name
        self._path = os.path.join(folder, name)
        self._messages = 0
        self._new = 0

    def __repr__(self):
        return self._name

    def __str__(self):
        return self.__repr__()

    name = property(lambda self: self._name)
    path = property(lambda self: self._path)


class Account(object):
    def __init__(self, filename, folder):
        self._logger = create_logger(self.__class__.__name__)
        self._file = filename
        self._mailboxes = []
        self._parse(folder)

    def __repr__(self):
        return repr(self._mailboxes)

    def __str__(self):
        return self.__repr__()

    def _parse(self, folder):
        with open(self._file) as f:
            self._logger.info('parsing %s' % self._file)
            for line in f:
                if line.startswith('mailboxes'):
                    self._parse_mailbox(line[10:-1], folder)

    def _parse_mailbox(self, mb_name, folder):
        if mb_name.startswith('"'):
            mb_name = mb_name[1:-1]
        if mb_name.startswith('$folder/'):
            self._mailboxes.append(MailBox(folder, mb_name[8:]))
        elif mb_name[0] in ['=', '+']:
            self._mailboxes.append(MailBox(folder, mb_name[1:]))
        else:
            self._logger.warn('unknown mailbox format %s' % mb_name)

    mailboxes = property(lambda self: self._mailboxes)


class MuttConfiguration(object):
    def __init__(self):
        self._logger = create_logger(self.__class__.__name__)
        if len(sys.argv) == 2:
            self._user = sys.argv[1]
        elif os.environ.has_key('USER'):
            self._user = os.environ['USER']
        elif os.environ.has_key('LOGNAME'):
            self._user = os.environ['LOGNAME']

        if not len(self._user):
            self._logger.error('no user name.')
            raise ValueError('no user name')

        self._root_path = os.path.join('/home', self._user)
        self._accounts = []
        self._folder = os.path.join(self._root_path, 'Mail')

    def parse(self):
        """Mutt configuration parser.

        This parser looks for folder settings in ~login/.mutt/muttrc
        and mailboxes setting in ~login/.mutt/accounts/*. It is not
        smart enough to distinguish hooks and it will happily
        aggregate any matching lines.
        """
        self._parse_muttrc(os.path.join(self._root_path, '.mutt/muttrc'))
        self._parse_accounts(os.path.join(self._root_path, '.mutt/accounts'))

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
        for f in os.listdir(path):
            if f.endswith('~'):
                self._logger.debug('ignore emacs backup %s' % f)
                continue
            self._accounts.append(Account(os.path.join(path, f), self._folder))

    accounts = property(lambda self: self._accounts)


class Synchroniser(object):
    """A simple wrapper around isync."""
    def __init__(self):
        self._logger = create_logger(self.__class__.__name__)

    def run(self):
        self._logger.info('synchronising boxes ...')
        proc = subprocess.Popen(
            ['mbsync', '-a'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        status_re = re.compile(
            '^Selecting (?P<side>\w+) (?P<name>.+)\.\.\. (?P<msg>\d+) messages, (?P<new>\d+) recent')
        current_pair = {}
        for line in proc.stdout:
            m = status_re.match(line)
            if m:
                current_pair[m.group('side')] = m.group('name')
            if len(current_pair) == 2:
                self._log_status(current_pair['slave'], current_pair['master'])
                current_pair = {}
        proc.wait()

    def _log_status(self, local, distant):
        self._logger.info('  %s <==> %s' % (local, distant))


class MailHandler(object):
    """A tool to sort and inspect mailboxes."""
    # TODO: port this class to the mailbox standard API. Will allow to
    #       distinguish unread from unseen mails, and parse mbox.
    def __init__(self, conf):
        self._logger = create_logger(self.__class__.__name__)
        self._conf = conf

    def sort(self):
        self._logger.info('sorting new mail ...')

        # First take a snapshot of new mails on every mailbox to be
        # sure they will ba handled only once.
        for box, mails in self._snapshot(self._conf.accounts).iteritems():
            self._logger.info('sorting %s ...' % box)
            for mail in mails:
                proc = subprocess.Popen(
                    'procmail',
                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                with open(os.path.join(box.path, 'new', mail)) as f:
                    # TODO: check procmail success.
                    proc.communicate(f.read())
                    print 'sorted out %s' % mail

                    try:
                        shutil.move(os.path.join(box.path, 'new', mail), '/tmp')
                        #if condition_success_procmail?:
                        #os.unlink(mail)

                    except IOError:
                        # It is possible the message was already
                        # edited through mutt, specially with
                        # spamassassin which is *very* slow :)
                        pass

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

        */5 * * * * source ~/.config/dbus_session; ~/bin/sync_mail.py > /tmp/mail.log
        """
        try:
            import dbus
        except ImportError:
            self._logger.warn('dbus module is not installed')
            return

        if not os.environ.has_key('DBUS_SESSION_BUS_ADDRESS'):
            self._logger.warn('DBus session not available')
            return

        sysbus = dbus.SessionBus()
        obj = sysbus.get_object('org.freedesktop.Notifications',
                                '/org/freedesktop/Notifications')
        itf = dbus.Interface(obj, 'org.freedesktop.Notifications')

        message = ''
        for box, mails in self._snapshot(self._conf.accounts).iteritems():
            if len(mails):
                message += '%d  new messages in %s\n' % (len(mails), box.name)

        if len(message):
            itf.Notify(
                'sync_mail.py', 0, '', 'New Mail!', message, [], {}, -1)
            self._logger.info('notification sent to dbus')

    def _snapshot(self, accounts):
        snapshot = {}
        for account in accounts:
            for box in account.mailboxes:
                path = os.path.join(box.path, 'new')
                if os.path.isdir(path):
                    snapshot[box] = os.listdir(path)
                else:
                    self._logger.warn(
                        '%s (%s) is not a valid maildir box ' % (box, box.path))
        return snapshot


# main

# if not check_connection():
#     logger.error('no available connection.')
#     sys.exit(1)

# 0. Read the Mutt configuration to get a single configuration source.
mutt_conf = MuttConfiguration()
mutt_conf.parse()

# 1. Synchronize distant and local mail. Update accounts information.
Synchroniser().run()

# 2. Sort incoming mail
mail_handler = MailHandler(mutt_conf)
mail_handler.sort()

# 3. Count new mails and notify the user through dbus.
mail_handler.notify()
