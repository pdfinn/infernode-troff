#!/usr/bin/env python3
# norm.py out: troff's device-independent output as lines of text,
# positions in points, so two troffs on different devices compare.
# Each line: page, y (points), x of its first glyph (points), then its
# words with [size font] when they change; drawings as D(...).
import re, sys

def parse(path):
    res = 720
    sizescale = 1
    fonts = {}
    page = 0
    h = v = 0
    size = 10
    font = 1
    out = []   # (page, v, h, text, size, fontname)
    data = open(path, encoding='utf-8', errors='replace').read()
    i = 0
    n = len(data)

    def num():
        nonlocal i
        m = re.compile(r'\s*(-?\d+)').match(data, i)
        if not m:
            return 0
        i = m.end()
        return int(m.group(1))

    def eol():
        nonlocal i
        j = data.find('\n', i)
        if j < 0:
            j = n
        s = data[i:j]
        i = j + 1
        return s

    while i < n:
        c = data[i]
        i += 1
        if c in ' \n\t':
            continue
        if c == 'x':
            l = eol().split()
            if l and l[0] == 'res':
                res = int(l[1])
            elif l and l[0] == 'font' and len(l) >= 3:
                fonts[int(l[1])] = l[2]
            elif l and l[0] == 'sizescale':
                sizescale = int(l[1])
            elif l and l[0] == 'X':
                out.append((page, v, h, 'X(' + ' '.join(l[1:]) + ')', size, fonts.get(font, font)))
            continue
        if c == 'p':
            page = num(); v = h = 0
        elif c == 's':
            size = num()
        elif c == 'f':
            font = num()
        elif c == 'H':
            h = num()
        elif c == 'V':
            v = num()
        elif c == 'h':
            h += num()
        elif c == 'v':
            v += num()
        elif c == 'c':
            ch = data[i]; i += 1
            out.append((page, v, h, ch, size, fonts.get(font, font)))
        elif c == 'C':
            m = re.compile(r'(\S+)').match(data, i); i = m.end()
            out.append((page, v, h, '\\(' + m.group(1) + ')', size, fonts.get(font, font)))
        elif c == 'N':
            k = num()
            out.append((page, v, h, '\\N%d' % k, size, fonts.get(font, font)))
        elif c.isdigit():
            ch2 = data[i]; i += 1
            h += int(c + ch2)
            ch = data[i]; i += 1
            out.append((page, v, h, ch, size, fonts.get(font, font)))
        elif c == 'w':
            pass
        elif c == 'n':
            num(); num()
        elif c == 'D':
            l = eol().split()
            k = l[0][0]
            out.append((page, v, h, 'D(' + k + ')', size, fonts.get(font, font)))
            # a drawing moves the point to its end, as troff counts it
            d = [int(x) for x in l[1:] if re.fullmatch(r'-?\d+', x)]
            if k in 'cC':
                h += d[0] if d else 0
            elif k in 'eE':
                h += d[0] if d else 0
            elif k != 't':
                h += sum(d[0::2])
                v += sum(d[1::2])
        elif c == '#':
            eol()
        else:
            eol()
    if sizescale == 1 and any(o[4] >= 400 for o in out):
        sizescale = 100
    return res, sizescale, out

def lines(path):
    res, ss, out = parse(path)
    k = 72.0 / res
    rows = {}
    for (pg, v, h, t, s, f) in out:
        rows.setdefault((pg, v), []).append((h, t, s, f))
    text = []
    for (pg, v) in sorted(rows):
        g = sorted(rows[(pg, v)], key=lambda r: r[0])
        s = ''
        last = None
        lastsf = None
        for (h, t, sz, f) in g:
            szp = sz / ss if ss > 1 else sz
            if last is not None and h * k - last > 1.5:
                s += ' '
            sf = (round(szp, 1), str(f))
            if sf != lastsf:
                s += '[%g %s]' % sf
                lastsf = sf
            s += t
            last = h * k + 4  # a rough glyph width
        text.append('p%d y=%.1f x=%.1f %s' % (pg, v * k, g[0][0] * k, s))
    return text

if __name__ == '__main__':
    print('\n'.join(lines(sys.argv[1])))
