#!/usr/bin/python

# Usage: notify.py timeout title content
#
# If timeout is -1, the notification uses the default timeout. If 0,
# it will stay displayed until acknowledged.

import dbus
import os
import sys

DBUS_DIR = '/home/david/.dbus/session-bus/'

def load_session():
    # For now, take the first session found.
    sessions = os.listdir(DBUS_DIR)
    if len(sessions):
        with open(os.path.join(DBUS_DIR, sessions[0]), 'r') as f:
            for line in f:
                if line.startswith('DBUS'):
                    key, value = line.split('=', 1)
                    os.environ[key] = value[:-1]

def get_session_bus():
    if not os.environ.has_key('DBUS_SESSION_BUS_ADDRESS'):
        load_session()
    return dbus.SessionBus()


notify_obj = get_session_bus().get_object('org.freedesktop.Notifications',
                                          '/org/freedesktop/Notifications')
notify_if = dbus.Interface(notify_obj, 'org.freedesktop.Notifications')
notify_if.Notify('notify.py', 0, '', sys.argv[2], sys.argv[3], [], {}, int(sys.argv[1]))
