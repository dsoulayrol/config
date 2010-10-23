#!/usr/bin/python
#
# remind2org.py converts the simple calendar output from remind in
# files suitable for orgmode.
#
# Usage: remind2org.py remind_file org_file
#
# org_file will be overwritten. It is aimed at being included in your
# org-agenda-files
#
# Thanks to original work from Dr. Detlef Steuer <steuer <at> hsu-hh.de>

import os, sys

REMIND = '/usr/bin/remind'

def process_remind_line(line):
    fields = line.split(' ')
    if len(fields) < 2:
        return
    scheduled = fields[0].replace('/','-')
    if fields[4] != '*':
        scheduled = ' '.join([scheduled, fields[5]])
    return '** ' + ' '.join(fields[5:]) + '   <' + scheduled + '>\n'

if __name__ == '__main__':
    if len(sys.argv) != 3 :
        print 'Usage: remind2org remindfile orgfile'
        sys.exit()

    cmd = ' '.join([REMIND, '-b1 -ss -c13', sys.argv[1]])
    with open(sys.argv[2], 'w') as f:
        f.write('* Calendar\n')
        f.write('#+CATEGORY: Remind\n')
        for e in os.popen(cmd).readlines():
            f.write(process_remind_line(e))

