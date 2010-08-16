#!/usr/bin/python

# Usage: notify.py timeout title content
#
# If timeout is -1, the notification uses the default timeout. If 0,
# it will stay displayed until acknowledged.

import dbus
import sys

sysbus = dbus.SessionBus()
notify_obj = sysbus.get_object('org.freedesktop.Notifications',
                              '/org/freedesktop/Notifications')
notify_if = dbus.Interface(notify_obj, 'org.freedesktop.Notifications')
notify_if.Notify('notify.py', 0, '', sys.argv[2], sys.argv[3], [], {}, int(sys.argv[1]))
