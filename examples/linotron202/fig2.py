#!/usr/bin/env python3
# fig2.py summer.reconstructed.pdf > e.pic: Figure 2's vectors as the
# 2013 reconstruction measured them from the 1980 memo (page 8 of its
# PDF, www.cs.princeton.edu/~bwk/202/summer.reconstructed.pdf):
# each arrow there is a shaft and two short strokes for its head; a
# shaft with a head is written as an arrow, one without as a line; a
# Create where vectors begin and none ends, a Destroy where they end.
import sys, re, math, pypdf

r = pypdf.PdfReader(sys.argv[1])
pg = r.pages[7]
c = pg.get_contents().get_data().decode('latin-1')

segs = []
cur = None
for m in re.finditer(r'(-?[\d.]+) (-?[\d.]+) ([ml])\b', c):
    x, y, op = float(m.group(1)), float(m.group(2)), m.group(3)
    if op == 'l' and cur is not None:
        segs.append((cur, (x, y)))
    cur = (x, y)
shaft = [s for s in segs if math.dist(*s) > 6]
head = [s for s in segs if math.dist(*s) <= 6]
def headed(s):
    e = s[1]
    return sum(1 for h in head if math.dist(h[1], e) < 1.2) >= 2

# Create where vectors begin and none ends, Destroy where they end and
# none begins: the points a pair of edges starts and stops
def near(a, b): return math.dist(a, b) < 1.5
labels = []
ends = [p for s in shaft for p in s]
for p in sorted(ends, key=lambda p: p[1]):     # lowest first: a pair begun a few points apart labelled where its lower edge begins
    if any(math.dist(p, q) < 8 for _, q, _ in labels): continue
    starts = sum(1 for s in shaft if near(s[0], p))
    stops = sum(1 for s in shaft if near(s[1], p))
    if starts and not stops: labels.append(('Create', p, starts))
    elif stops and not starts: labels.append(('Destroy', p, stops))
# a pair begins, and ends, at one point (the reconstruction's trace
# starts the counter's bowl a few points above its bar): each vector's
# end within that distance of a Create or Destroy moved onto it
def snap(p, kind):
    for t, q, _ in labels:
        if t == kind and math.dist(p, q) < 8: return q
    return p
shaft = [(snap(a, 'Create'), snap(b, 'Destroy')) for a, b in shaft]
pts = [p for s in shaft for p in s]
x0 = min(p[0] for p in pts); y0 = min(p[1] for p in pts)
ht = max(p[1] for p in pts) - y0
wd = max(p[0] for p in pts) - x0
S = 4.0 / ht        # four inches high
# the 1980 scan's proportions (its drawing 0.804 as wide as high, the
# page itself letter's to half a percent); the reconstruction drew it
# some 6% wider
ASPECT = 0.804
SX = ASPECT * 4.0 / wd
def P(p): return '(%.3f, %.3f)' % ((p[0] - x0) * SX, (p[1] - y0) * S)

print('.PS')
print('arrowht = 0.08; arrowwid = 0.045; arrowhead = 7')
for s in shaft:
    print('%s from %s to %s' % ('arrow' if headed(s) else 'line', P(s[0]), P(s[1])))
for t, p, n in labels:
    # small, as the memo's are
    if t == 'Create': print('"\\s8Create\\s0" rjust at %s - (0.06, 0)' % P(p))
    else: print('"\\s8Destroy\\s0" ljust at %s + (0.06, 0)' % P(p))
print('.PE')
sys.stderr.write('%d shafts (%d headed), %d heads, %d labels\n' % (len(shaft), sum(map(headed, shaft)), len(head), len(labels)))
