#!/usr/bin/env python
# xchat-minbif.py, some tweaks for using minbif with xchat.
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
This script replicates presence information emitted by minbif with the
voice and devoice event on the opened dialogs.

To install:

  o For autoload on startup, copy this file to your xchat directory,
    probably ~/.xchat2.

  o To load without restart, run: /py load xchat-minbif.py
    (If you don't want to put it in your ~/.xchat2, then specify the full path.)

If running the '/py' command above results in a message 'py :Unknown
 command', then you do not have the Python plugin installed.
"""

try:
    import xchat
except ImportError:
    print "This module must be run inside XChat."
    exit(1)


__author__              = 'David Soulayrol <david.soulayrol at gmail.com>'
__module_name__         = 'xchat-minbif'
__module_version__      = '0.1'
__module_description__  = 'TODO'


class Monitor(object):
    """An object monitoring contacts presence to replicate it."""

    def __init__(self):
        pass

    def setup(self):
        # Register contact events raised by minbif.
        xchat.hook_print('Channel DeVoice', self.replicate_event, (1, 'is away'))
        xchat.hook_print('Channel Voice', self.replicate_event, (1, 'is back'))
        xchat.hook_print('Join', self.replicate_event, (0, 'has joined'))

        # The following is already notified.
        #xchat.hook_print('Quit', self.replicate_event, (0, 'has quit'))

        xchat.hook_unload(self.unload_cb)

        xchat.prnt('%s version %s by %s loaded' % (
                __module_name__, __module_version__, __author__))

    def replicate_event(self, word, word_eol, userdata):
        nick_idx, tag = userdata
        for c in self._get_channels(word[nick_idx]):
            c.prnt(word[nick_idx] + ' ' + tag)
        return xchat.EAT_NONE

    def unload_cb(self, userdata):
        xchat.prnt('%s unloaded' % __module_name__)

    def _get_channels(self, nick):
        return [i.context for i in xchat.get_list('channels')
                if i.type == 3 and 0 == xchat.nickcmp(i.channel, nick)]

if __name__ == '__main__':
    Monitor().setup()
