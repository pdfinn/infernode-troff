#!/usr/bin/env python3
# mathbook.py — a long book of mathematics for timing book(1) against
# LaTeX (docs/TROFF.md, Speed): 30 chapters of three sections, eight
# paragraphs each with two inline equations, and after every second
# paragraph a numbered display, tests/eqn/hard.ms's in turn.
#
#	python3 tools/mathbook.py >mbook.ms
#	book mbook.ms; book2tex -o mbook.tex mbook.ms
import os, random, re, sys

here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, '..', 'tests', 'eqn', 'hard.ms'), encoding='utf-8').read()
disp = [b.strip() for b in re.findall(r'\.EQ\n(.*?)\n\.EN', src, re.S)]
inl = ["x sup 2 + y sup 2 = r sup 2", "alpha over beta", "sqrt {a + b}", "f ( x ) = e sup {- x}",
       "sum from {i = 1} to n i", "int from 0 to 1 x dx", "n choose k", "x hat", "{x + y} bar",
       "lim from {n -> inf} a sub n", "p sub i sup 2", "omega sub 0 t", "theta hat", "a sub {i j}",
       "{1 over 2} log n", "nabla cdot bold E", "x sub 1 , ... , x sub n"]
words = ("the of and a to in is that for it as was with be by on not he this are or his from at "
         "which but have an they you were her she there would their we him been has when who will "
         "more no if out so said what up its about into than them can only other new some could "
         "time these two may then do first any my now such like our over man me even most made "
         "after also did many before must through back years where much your way well down should "
         "because each just those people how too little state good very make world still own see "
         "men work long get here between both life being under never day same another know while "
         "last might us great old year off come since against go came right used take three").split()
random.seed(7)

def para():
    n = random.randint(90, 120)
    m = random.sample(range(10, n - 5), 2)
    ws = []
    for i in range(n):
        ws.append(random.choice(words))
        if i in m:
            ws.append('$' + random.choice(inl) + '$')
    s = ' '.join(ws)
    s = s[0].upper() + s[1:] + '.'
    lines, cur = [], ''
    for w in s.split(' '):
        if len(cur) + len(w) > 70 and not cur.count('$') % 2:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + ' ' + w).strip()
    lines.append(cur)
    return '\n'.join(lines)

out = ['.title "Mathematics at Length"', '.author "A Benchmark"', '.date "2026"', '.maketitle',
       '.frontmatter', '.contents', '.mainmatter', '.EQ', 'delim $$', '.EN']
k = 0
for c in range(1, 31):
    out.append('.chapter "Chapter %d" ch%d' % (c, c))
    n = 0
    for s in range(1, 4):
        out.append('.section "Section %d.%d"' % (c, s))
        for p in range(8):
            out += ['', para()]
            if p % 2:
                n += 1
                out += ['.EQ (%d.%d)' % (c, n), disp[k % len(disp)], '.EN']
                k += 1
sys.stdout.write('\n'.join(out) + '\n')
