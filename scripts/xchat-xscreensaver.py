#!/usr/bin/env python
# xchat-xscreensaver.py, a script to notify xscreensaver activity to xchat.
# Copyright (C) 2010  David Soulayrol <david.soulayrol@gmail.com>
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
This script brings xscreensaver activity notifications to xchat, thus
allowing simple and automatic presence detection.

To install:

  o For autoload on startup, copy this file to your xchat directory,
    probably ~/.xchat2.

  o To load without restart, run: /py load xchat-xscreensaver.py
    (If you don't want to put it in your ~/.xchat2, then specify the full path.)

If running the '/py' command above results in a message 'py :Unknown
 command', then you do not have the Python plugin installed.
"""

import os
import select
import signal
import subprocess
import sys

try:
    import xchat
except ImportError:
    print "This module must be run inside XChat."
    exit(1)


__author__              = 'David Soulayrol <david.soulayrol at gmail.com>'
__module_name__         = 'xchat-xscreensaver'
__module_version__      = '0.1'
__module_description__  = 'Updates presence on xscreensaver notifications'


class Monitor(object):
    """An object monitoring xscreensaver status for xchat."""

    POLLING_PERIOD = 5000

    def __init__(self):
        self._process = None
        self._hook = None

    def setup(self):
        self._process = self._create_pipe()

        # Register timed check of screensaver status.
        self._hook = self._register_hook()

        xchat.hook_unload(self.unload_cb)

        # Register some commands.
        xchat.hook_command("xs_start_polling", self.on_start)
        xchat.hook_command("xs_stop_polling", self.on_stop)

        xchat.prnt('%s version %s by %s loaded' % (
                __module_name__, __module_version__, __author__))

    def poll_status_cb(self, userdata):
        self._process.poll()
        if self._process.returncode is None:
            rl, wl, xl = select.select([self._process.stdout], [], [], 0)
            if len(rl):
                event = self._process.stdout.readline()
                if event.startswith('BLANK') or event.startswith('LOCK'):
                    xchat.command('away %s' % xchat.get_prefs('away_reason'))
                elif event.startswith('UNBLANK'):
                    xchat.command('back')
        else:
            # pipe is broken.
            self._process = self._create_pipe()

        # Keep the timeout going
        return 1

    def unload_cb(self, userdata):
        v = sys.version_info
        if v[0] == 2 and v[1] < 6:
            os.kill(self._process.pid, signal.SIGTERM)
        else:
            self._process.terminate()
        self._process = None
        xchat.prnt('%s unloaded' % __module_name__)

    def on_start(self, word, word_eol, userdata):
        if self._hook is None:
            self._hook = self._register_hook()
            xchat.prnt('%s activated' % __module_name__)
        return xchat.EAT_ALL

    def on_stop(self, word, word_eol, userdate):
        if self._hook is not None:
            xchat.unhook(self._hook)
            xchat.prnt('%s deactivated' % __module_name__)
            self._hook = None
        return xchat.EAT_ALL

    def _register_hook(self):
        return xchat.hook_timer(Monitor.POLLING_PERIOD, self.poll_status_cb)

    def _create_pipe(self):
        return subprocess.Popen(['xscreensaver-command', '-watch'],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)


if __name__ == '__main__':
    Monitor().setup()
