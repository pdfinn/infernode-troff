#!/usr/bin/env python3
# figa2.py > a2.pic: Figure A2 measured from the 1980 scan (page 14 at
# 150 pixels an inch, y down, the crop at 120,60), so each part is
# where and as large as the original drew it.  The second half's
# flip-flop (ff1) and the lines into it did not print in the scan; they
# are drawn as the first half's.
import math

out = []
def P(x, y): return '(%g,%g)' % (x, -y)
def line(*pts, arrow=False):
    out.append('%s from %s %s' % ('arrow' if arrow else 'line', P(*pts[0]), ' '.join('to ' + P(*p) for p in pts[1:])))
def text(x, y, s, adj='', size=8):
    out.append('"\\s%d\\f(CW%s\\fP\\s0" %s at %s' % (size, s, adj, P(x, y)))
def box(x0, y0, x1, y1): line((x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0))
def bubble(x, y, r=5): out.append('circle rad %g at %s' % (r, P(x, y)))
def inv(x, y, w=46, h=44):
    line((x, y - h / 2), (x + w, y), (x, y + h / 2), (x, y - h / 2)); bubble(x + w + 5, y)
    return x + w + 10
def nand(x, y, w=64, h=42):
    f = x + w - h / 2
    pts = [(f, y - h / 2), (x, y - h / 2), (x, y + h / 2), (f, y + h / 2)]
    pts += [(f + h / 2 * math.sin(math.pi * k / 12), y + h / 2 * math.cos(math.pi * k / 12)) for k in range(1, 13)]
    line(*pts); bubble(x + w + 5, y)
    return x + w + 10
def res(x, y, w=22, h=10): box(x, y - h / 2, x + w, y + h / 2)
def conn(x, y): line((x - 9, y - 6), (x, y), (x - 9, y + 6))

def half(dy, cin, ina, inb, pa, pb, ip, op, rq, rqp, rqj, rqjp, np, csr, csrj, csrp, ff, dr, drj, drp, drg, og, oname, oj, ojp):
    Y = lambda y: y + dy
    # the il100, its VCC loop
    box(390, Y(107), 455, Y(175)); text(422, Y(142), 'il100')
    text(403, Y(73), 'VCC'); line((368, Y(80)), (418, Y(80)), (418, Y(107)))
    line((368, Y(80)), (368, Y(113)), (390, Y(113)))
    text(432, Y(97), ip[0]); text(375, Y(128), ip[1])
    # its inputs: + through a resistor
    for y, lab, pin, bpin, r in ((140, ina, pa, ip[2], True), (163, inb, pb, ip[3], False)):
        text(198, Y(y), cin, 'rjust'); conn(215, Y(y))
        if r:
            line((215, Y(y)), (313, Y(y))); res(313, Y(y)); line((335, Y(y)), (390, Y(y)))
        else:
            line((215, Y(y)), (390, Y(y)))
        text(250, Y(y - 12), lab, 'ljust'); text(237, Y(y + 11), pin); text(380, Y(y + 9), bpin)
    # out through an inverter to rq; the junction down to the nand
    line((455, Y(127)), (520, Y(127))); text(467, Y(118), op[0]); text(505, Y(118), op[1])
    out.append('circle rad 2 fill at %s' % P(488, Y(127)))
    gx = inv(520, Y(127)); line((gx, Y(127)), (690, Y(127)), arrow=True)
    text(628, Y(116), rq); text(590, Y(137), rqp); text(659, Y(137), rqjp); text(696, Y(127), rqj, 'ljust')
    line((488, Y(127)), (488, Y(187)), (510, Y(187)))
    gx = nand(510, Y(196)); text(540, Y(196), 'ls00')
    text(500, Y(184), np[0]); text(500, Y(208), np[1]); text(588, Y(206), np[2])
    # csr into the nand's lower input
    text(244, Y(205), csrj, 'rjust'); conn(260, Y(205)); line((260, Y(205)), (510, Y(205)))
    text(307, Y(193), csr); text(292, Y(218), csrp)
    # the nand to the flip-flop; the il100's ground to it
    line((gx, Y(196)), (598, Y(196)), (598, Y(225)))
    text(432, Y(186), ip[4]); line((420, Y(175)), (420, Y(233)), (565, Y(233)))
    text(467, Y(226), 'GND')
    # the strobe through an inverter into the flip-flop
    text(244, Y(256), drj, 'rjust'); conn(260, Y(256)); line((260, Y(256)), (345, Y(256)))
    text(300, Y(245), dr); text(292, Y(270), drp)
    gx = inv(345, Y(256)); text(336, Y(266), drg[0]); text(407, Y(266), drg[1])
    line((gx, Y(256)), (565, Y(256)))
    box(565, Y(225), 630, Y(295)); text(598, Y(256), ff[0]); text(598, Y(275), ff[1])
    line((630, Y(285)), (675, Y(285)))
    # out through an inverter, a resistor each side, to the connector
    gx = inv(675, Y(285)); text(662, Y(299), og[0]); text(738, Y(297), og[1])
    line((gx, Y(287)), (808, Y(287))); res(808, Y(287)); line((830, Y(287)), (917, Y(287)), arrow=True)
    line((750, Y(263)), (808, Y(263))); res(808, Y(263)); line((830, Y(263)), (917, Y(263)), arrow=True)
    text(773, Y(257), 'VCC'); text(868, Y(256), oname + '+'); text(866, Y(279), oname + '-')
    text(889, Y(272), ojp[0]); text(889, Y(297), ojp[1])
    text(923, Y(263), oj, 'ljust'); text(923, Y(287), oj, 'ljust')

half(0, 'CC', 'ac1+', 'ac1-', '25', '26', ('16', '15', '2', '3', '13'), ('14', '13'), 'rqsta+', '12', 'J1', '32',
     ('5', '4', '6'), 'csr1', 'J1', '26', ('ff0', 'ls74'), 'ndry+', 'J1', '40', ('5', '6'), ('9', '8'), 'sc1', 'CC', ('19', '20'))
half(334, 'CD', 'sc2+', 'sc2-', '19', '20', ('12', '11', '6', '7', '9'), ('10', '11'), 'rqstb+', '10', 'J2', '15',
     ('2', '1', '3'), 'csr0', 'J2', '9', ('ff1', 'ls74'), 'dxmt+', 'J2', '3', ('9', '8'), ('11', '10'), 'ac2', 'CD', ('25', '26'))

print('.PS\nscale = 150\narrowht = 9; arrowwid = 5; arrowhead = 7\n' + '\n'.join(out) + '\n.PE')
