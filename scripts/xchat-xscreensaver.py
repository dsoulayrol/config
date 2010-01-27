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

  o To load without restart, run: /py load xchat-away.py
    (If you don't want to put it in your ~/.xchat2, then specify the full path.)

If running the '/py' command above results in a message 'py :Unknown
 command', then you do not have the Python plugin installed.
"""

import select
import subprocess
import xchat

__author__              = 'David Soulayrol <david.soulayrol at gmail.com>'
__module_name__         = 'xchat-xscreensaver'
__module_version__      = '0.1'
__module_description__  = 'Updates presence on xscreensaver notifications'

class Monitor(object):
    def __init__(self):
        self.process = None
        self.hook = None

    def setup(self):
        self.process = subprocess.Popen(['xscreensaver-command', '-watch'],
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # Register timed check of screensaver status.
        self.register_hook()

        xchat.hook_unload(self.unload_cb)

        # Register some commands.
        xchat.hook_command("START_XS", self.on_start)
        xchat.hook_command("STOP_XS", self.on_stop)

    def register_hook(self):
        self.hook = xchat.hook_timer(5000, self.check_xscreensaver_cb)

    def check_xscreensaver_cb(self, userdata):
        # TODO: check the pipe is not broken

        rl, wl, xl = select.select([monitor.process.stdout], [], [], 0)
        if len(rl):
            event = self.process.stdout.readline()
            if event.startswith('BLANK') or event.startswith('LOCK'):
                xchat.command('away %s' % xchat.get_prefs('away_reason'))
            elif event.startswith('UNBLANK'):
                xchat.command('back')

        # Keep the timeout going
        return 1

    def unload_cb(self, userdata):
        self.process.terminate()

    def on_start(self, word, word_eol, userdata):
        if self.hook is None:
            self.register_hook()
            xchat.prnt('%s activated' % __module_name__)
        return xchat.EAT_ALL


    def on_stop(self, word, word_eol, userdate):
        if self.hook is not None:
            xchat.unhook(self.hook)
            xchat.prnt('%s deactivated' % __module_name__)
        return xchat.EAT_ALL


if __name__ == '__main__':
    monitor = Monitor()

    monitor.setup()

    xchat.prnt('%s version %s by %s loaded' % (
            __module_name__, __module_version__, __author__))
