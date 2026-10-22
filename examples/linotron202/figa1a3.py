#!/usr/bin/env python3
# figa1a3.py: pic for Figures A1 and A3 of the Linotron 202 memo,
# written to a1.pic and a3.pic.  Coordinates are pixels of the 2013
# reconstruction's pages at 110 an inch, y down, so each part goes where
# it was drawn there; A1's IL100s are measured from the 1980 scan (its
# own scale noted where they are drawn).

def T(s, size=7): return '"\\s%d\\f(CW%s\\fP\\s0"' % (size, s)

class Pic:
    def __init__(self): self.l = []
    def __call__(self, s): self.l.append(s)
    def P(self, x, y): return '(%g,%g)' % (x, -y)
    def line(self, *pts, arrow=False):
        self('%s from %s %s' % ('arrow' if arrow else 'line', self.P(*pts[0]),
            ' '.join('to ' + self.P(*p) for p in pts[1:])))
    def text(self, x, y, s, adj='', size=7):
        self('%s %s at %s' % (T(s, size), adj, self.P(x, y)))
    def num(self, x, y, s, adj=''): self.text(x, y, s, adj, 6)
    def box(self, x0, y0, x1, y1):
        self.line((x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0))
    def inv(self, x, y, w=20, h=20):
        "an inverter from x to x+w, its bubble after"
        self.line((x, y - h/2), (x + w, y), (x, y + h/2), (x, y - h/2))
        self('circle rad 3 at %s' % self.P(x + w + 3, y))
        return x + w + 6
    def res(self, x, y, w=10, h=6):
        self.box(x, y - h/2, x + w, y + h/2)
    def nand(self, x, y, w=50, h=34):
        "a NAND gate, its flat back at x; returns where its output starts"
        import math
        f = x + w - h/2
        pts = [(f, y - h/2), (x, y - h/2), (x, y + h/2), (f, y + h/2)]
        pts += [(f + h/2 * math.sin(math.pi * k / 12), y + h/2 * math.cos(math.pi * k / 12)) for k in range(1, 13)]
        self.line(*pts)
        self('circle rad 3 at %s' % self.P(x + w + 3, y))
        return x + w + 6
    def conn(self, x, y):
        "a connector's > at x"
        self.line((x - 4, y - 3), (x, y), (x - 4, y + 3))
    def write(self, name):
        with open(name, 'w') as f:
            f.write('.PS\nscale = 110\narrowht = 6; arrowwid = 3\nlinethick = 0.4\n')
            f.write('\n'.join(self.l) + '\n.PE\n')

# ---- Figure A1: the interface between the Linotron 202 and the DR11-C
a = Pic()
rows = [  # y, J1 pin, gate pins in/out, do name, do+ pin, do- pin
    (617, '3', '1', '2', 'do8', '15', '16'),
    (655, '9', '3', '4', 'do7', '13', '14'),
    (692, '34', '5', '6', 'do6', '11', '12'),
    (727, '17', '9', '8', 'do5', '7', '8'),
    (772, '10', '11', '10', 'do4', '5', '6'),
    (805, '12', '13', '12', 'do3', '3', '4'),
    (840, '14', '1', '2', 'do2', '1', '2'),
    (880, '16', '3', '4', 'do1', '1', '2'),
]
parx = [165, 178, 192, 205, 218, 232, 248, 262]
parp = ['13', '12', '11', '10', '9', '8', '2', '1']
VX = 336
a.text(VX - 8, 597, 'VCC', 'rjust')
a.line((VX - 30, 600), (VX, 600), (VX, 912))
def outpair(y, gx, name, pp, pm, lab=None):
    # + from VCC through a resistor, - from the gate through one
    yp = y - 17
    a.line((VX, yp), (VX + 6, yp)); a.res(VX + 6, yp); a.line((VX + 16, yp), (410, yp), arrow=True)
    a.line((gx, y), (VX + 6, y)); a.res(VX + 6, y); a.line((VX + 16, y), (410, y), arrow=True)
    a.text(VX + 22, yp - 4, name + '+', 'ljust'); a.text(VX + 22, y - 4, name + '-', 'ljust')
    a.num(390, yp + 5, pp); a.num(390, y + 5, pm)
    a.text(414, yp, 'CC', 'ljust'); a.text(414, y, 'CC', 'ljust')
for i, (y, jp, gi, go, nm, pp, pm) in enumerate(rows):
    a.text(122, y, 'J1', 'rjust'); a.conn(132, y); a.num(135, y + 7, jp, 'ljust')
    a.line((132, y), (282, y))
    a.line((parx[i], y), (parx[i], 905))
    a.text(255, y - 7, 'out%d' % i, 'ljust'); a.num(270, y + 9, gi)
    gx = a.inv(284, y)
    a.num(gx + 4, y + 9, go)
    outpair(y, gx, nm, pp, pm)
# the second J1 pin on out2's row
a.text(122, 680, 'J1', 'rjust'); a.conn(132, 680); a.line((132, 680), (150, 680), (150, 692)); a.num(135, 686, '36', 'ljust')
# the parity generator
a.box(150, 905, 268, 932)
for x, p in zip(parx, parp): a.num(x, 912, p)
a.text(209, 921, 'par'); a.text(209, 941, 'ls280', size=6)
a.text(132, 905, 'H', 'rjust'); a.line((136, 905), (150, 905))
a.text(270, 905, 'o8', 'ljust'); a.num(272, 916, '6 5', 'ljust')
a.line((268, 920), (284, 920)); gx = a.inv(284, 920); a.num(gx + 2, 928, '6')
outpair(920, gx, 'par', '17', '18')
# the grounded pins
a.text(470, 589, 'GND', 'rjust'); a.line((450, 593), (497, 593)); a.line((480, 593), (480, 950))
gnd = [('J2', p) for p in '8 10 14 16 20 23 26 30 33 35 37 39 22 21 19 18 17 13 12 11'.split()] + \
      [('J1', p) for p in '8 18 21 25 27 31 33 35 37 39'.split()]
for k, (j, p) in enumerate(gnd):
    y = 602 + k * 11.8
    a.num(484, y - 4, p, 'ljust'); a.line((480, y + 2), (497, y + 2), arrow=True); a.text(500, y + 2, j, 'ljust')
a.num(484, 602 + len(gnd) * 11.8 - 2, '39', 'ljust')
# the opto-isolators, IL100s, and the drivers into the 11/70
ins = [('di8', '15', '16', 'in0', '1', '2', '38'), ('di7', '13', '14', 'in1', '3', '4', '32'),
       ('di6', '11', '12', 'in2', '5', '6', '5'), ('di5', '9', '10', 'in3', '9', '8', '24'),
       ('di4', '7', '8', 'in4', '11', '10', '31'), ('di3', '5', '6', 'in5', '13', '12', '29'),
       ('di2', '3', '4', 'in6', '1', '2', '27'), ('di1', '1', '2', 'in7', '3', '4', '25')]
OV = 607; OG = 680
a.text(OV - 8, 568, 'VCC', 'ljust'); a.line((585, 572), (OV + 20, 572))
# measured from the 1980 scan: each IL100 a square box, 0.32 inch a
# side, 0.49 apart; the ground pin off its lower right to the GND bus
P1 = 53.5
for k, (dn, dp, dm, inn, ip, io, jp) in enumerate(ins):
    t = 580 + k * P1
    ev = k % 2 == 0
    a.box(627, t, 662, t + 36)
    a.text(645, t + 18, 'il100', size=6)
    top, lp, ap, bp, op, gp = ('16', '15', '2', '3', '14', '13') if ev else ('12', '11', '6', '7', '10', '9')
    a.line((635, t), (635, t - 6), (OV, t - 6)); a.num(638, t - 4, top, 'ljust')
    a.line((OV, t + 8), (627, t + 8)); a.num(624, t + 3, lp, 'rjust')
    # inputs: CD, a resistor on +
    y1, y2 = t + 18, t + 30
    a.text(550, y1, 'CD', 'rjust'); a.conn(557, y1)
    a.text(550, y2, 'CD', 'rjust'); a.conn(557, y2)
    # label, then the resistor, then the VCC rail (x 607), then the box
    a.line((557, y1), (592, y1)); a.res(592, y1, 9); a.line((601, y1), (627, y1))
    a.line((557, y2), (627, y2))
    a.text(568, y1 - 5, dn + '+', 'ljust', 6); a.text(568, y2 - 5, dn + '-', 'ljust', 6)
    a.num(559, y1 + 6, dp, 'ljust'); a.num(559, y2 + 7, dm, 'ljust')
    a.num(625, y1 - 5, ap, 'rjust'); a.num(625, y2 - 5, bp, 'rjust')
    # out: to an inverter, to J2; the ground pin to the bus
    yo = t + 10
    a.line((662, yo), (692, yo)); a.num(667, yo - 4, op, 'ljust'); a.num(686, yo - 4, ip)
    gx = a.inv(692, yo); a.line((gx, yo), (762, yo), arrow=True)
    a.text(722, yo - 7, inn, 'ljust'); a.num(gx + 4, yo + 9, io); a.num(735, yo + 9, jp)
    a.text(766, yo, 'J2', 'ljust')
    a.line((662, t + 32), (OG, t + 32)); a.num(666, t + 30, gp, 'ljust')
a.line((OV, 572), (OV, 580 + 7 * P1 + 8))
a.text(OG + 2, 606, 'GND', 'ljust'); a.line((OG, 612), (OG, 580 + 7 * P1 + 32))
a.write('a1.pic')

# ---- Figure A2: figa2.py, measured from the 1980 scan

# ---- Figure A3: the interface timing
c = Pic()
rows = [(690, 'ac2, ac1'), (735, 'rqsta'), (780, 'ndry'), (822, 'sc1, sc2'), (865, 'rqstb'), (907, 'dxmt')]
for y, s in rows: c.text(193, y - 6, s, 'ljust')
L, R = 193, 688
# ac2, ac1: two edges, either may be first; down when the data is taken, up again
c.line((L, 705), (265, 705), (290, 667), (300, 667), (527, 667), (540, 690), (585, 690), (597, 667), (R, 667))
c.line((275, 705), (300, 667))
# rqsta
c.line((L, 745), (277, 745), (300, 710), (R, 710))
c.line((288, 745), (310, 710))
c.line((541, 710), (541, 733), (585, 733), (585, 710))
# ndry: a pulse, then the next
c.line((L, 789), (348, 789), (348, 765), (372, 765), (372, 789), (663, 789), (663, 765), (R, 765))
# sc1, sc2
c.line((L, 832), (398, 832), (413, 806), (553, 806), (568, 832), (R, 832))
# rqstb
c.line((L, 872), (420, 872), (420, 848), (578, 848), (578, 872), (R, 872))
# dxmt: its pulse
c.line((L, 915), (495, 915), (495, 890), (518, 890), (518, 915), (R, 915))
# the program starts
c.line((328, 637), (328, 1003))
c.text(193, 950, 'program starts', 'ljust'); c.line((193, 960), (315, 960), arrow=True)
# what causes what
for p, q in [((290, 757), (342, 775)), ((373, 798), (395, 815)), ((398, 840), (413, 862)),
             ((432, 878), (490, 903)), ((505, 882), (525, 680)), ((541, 698), (541, 718)),
             ((545, 740), (555, 800)), ((595, 735), (655, 780)), ((588, 673), (588, 700))]:
    c.line(p, q, arrow=True)
c('spline -> from %s to %s to %s to %s' % (c.P(570, 815), c.P(625, 735), c.P(630, 680), c.P(592, 682)))
c('spline -> from %s to %s to %s' % (c.P(432, 995), c.P(380, 880), c.P(313, 775)))
c.line((444, 995), (444, 885), arrow=True)
c.line((623, 1003), (623, 765), arrow=True)
c.text(432, 1008, 'Computer interrupt time.', 'ljust')
c.write('a3.pic')
