#!/usr/bin/python
#
# remind.py, reads iCal files, handle reminders, notifies the desktop.
# Copyright (C) 2009 David Soulayrol <david.soulayrol AT gmail DOT net>
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

#
# Depends on python-vobject.
#

#
# Inspired from ical2rem.pl, from Justin B. Alcorn.
#

from __future__ import with_statement # This isn't required in Python 2.6

import contextlib
import errno
import os
import sys

import vobject

from optparse import OptionParser



class LockError(Exception):
    """Exception raised on lock failure."""
    pass

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


REMIND_ROOT = os.path.join(os.environ['HOME'], '.remind')

# Declare how many days in advance to remind
DEFAULT_LEAD_TIME = "3"



def translate_ical_event(event):
    """Return the remind line.
    """
    start = event.vevent.dtstart.value

    line = u'REM ' + start.strftime('%b %d %Y')

    if 'leadtime' in event.vevent.contents:
        line += ' +' + event.vevent.leadtime
    else:
        line += ' +' + DEFAULT_LEAD_TIME

    if start.hour:
        line += ' AT ' + start.strftime('%H:%M')
    else:
        line += ' MSG %a '

    if 'dtend' in event.vevent.contents:
        duration = event.vevent.dtend.value - start
        seconds = duration.days * 86400 + duration.seconds
        line += ' DURATION ' + str(seconds / 3600) + ':' + str((seconds % 3600) / 60)

    line += ' SCHED _sfun MSG %a %2 %\"' + event.vevent.summary.value + '%\"'

    if 'location' in event.vevent.contents:
        line += ' at ' + event.vevent.location.value
    line += '%\n'

    return line


def store_remind_event(event, output):
    try:
        # Install lock.
        with flock(os.path.join(REMIND_ROOT, 'lock')):
            with open(output, 'a') as f:
                f.write(event.encode('utf8'))

    except LockError:
        sys.exit(2)


def parse_ical_events(stream, output):
    """
    """
    cal = vobject.readOne(stream)
    store_remind_event(translate_ical_event(cal), output)


# Main.
parser = OptionParser(usage='usage: %prog [options] store')
parser.set_defaults(output='~/TODO')
parser.add_option("-v", "--verbose",
                  action="store_true", dest="verbose", default=False,
                  help="make lots of noise")
parser.add_option("-q", "--quiet",
                  action="store_false", dest="verbose",
                  help="be quiet [default]")
parser.add_option("-o", "--output",
                  metavar="FILE", help="write output to FILE"),

(options, args) = parser.parse_args()

if args[0] == 'store':
    parse_ical_events(sys.stdin, options.output)
