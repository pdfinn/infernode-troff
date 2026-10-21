#!/usr/bin/env python3
# ci-tree.py tree infernode package: the tree the tests run in, an
# InferNode's with this package's laid over it (the tests' ROOT): each
# name is the first tree's that has it, a directory both have made and
# its names laid over again; links, nothing copied
import os, sys

def union(dst, srcs):
    os.makedirs(dst, exist_ok=True)
    names = []
    for s in srcs:
        for n in sorted(os.listdir(s)):
            if n not in names and n != '.git':
                names.append(n)
    for n in names:
        have = [os.path.join(s, n) for s in srcs if os.path.lexists(os.path.join(s, n))]
        dirs = [h for h in have if os.path.isdir(h)]
        d = os.path.join(dst, n)
        if len(dirs) > 1:
            union(d, dirs)
        elif not os.path.lexists(d):
            os.symlink(os.path.realpath(have[0]), d)

if len(sys.argv) != 4:
    sys.exit('usage: ci-tree.py tree infernode package')
union(sys.argv[1], sys.argv[2:])
