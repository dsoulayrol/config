#!/usr/bin/env python

# Convert a pass phrase into a numeric sequence.
import getpass

p = getpass.getpass()
n = 0
for i in range(len(p)):
    n += ord(p[i]) << i
print n, '(truncate or zero-pad by the left)'
