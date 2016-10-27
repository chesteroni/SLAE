#!/usr/bin/python

import sys
import itertools

input = sys.argv[1]

def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return itertools.izip_longest(fillvalue=fillvalue, *args)

groups = list(grouper(input,4,''))

for g in reversed(groups):
    rev = ''.join(g[::-1])
    print rev + ' | 0x' + rev.encode('hex')

