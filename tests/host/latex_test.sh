#!/bin/sh
#
# latex_test.sh — book2tex(1) for journals and for LuaLaTeX, accepted: the
# same troff source set by troff and written as LaTeX for each class,
# and the LaTeX checked as a journal's submission system would take it.
#
#	tests/latex/paper.ms, a technical paper (-marticle, refer's numbered
#	citations), written for IEEEtran (journal and conference), acmart
#	(acmsmall and sigconf) and LaTeX's article (LuaLaTeX, biblatex);
#	tests/latex/essay.ms, an essay in the humanities (one column, the
#	Chicago Manual's notes), for LaTeX's article (biblatex-chicago's
#	notes, and its author-date); examples/*.ms, each for its own class.
#
#	The LaTeX: written with nothing said on standard error; every
#	section, subsection, float, numbered equation, note, label and
#	citation of the source there, once; every environment and brace
#	closed; for pdfLaTeX (a journal's) every character one inputenc
#	knows or a command; the journal's class, bibliography style and
#	conventions (IEEEtran's keywords and its tables' captions above
#	them; acmart's affiliations with their countries, the abstract
#	before \maketitle, a description of each figure); tables' rules
#	booktabs', none upright.
#	Where pdfLaTeX, LuaLaTeX, BibTeX and biber and the classes are
#	installed: each set with no error, no reference or citation left
#	undefined, no character missing from a font, every work cited in
#	the bibliography; then every word troff set (bar running heads,
#	folios and what the classes word otherwise: references, captions'
#	names, keywords' heading) in LaTeX's PDF too, and the names with
#	accents and LaTeX's special characters as they were written.

. "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -x "$EMU" ] || { echo "latex_test: SKIP (no emu)"; exit 77; }
[ -f "$ROOT/dis/book2tex.dis" ] && [ -f "$ROOT/dis/troff.dis" ] ||
    { echo "latex_test: SKIP (dis not built)"; exit 77; }
command -v python3 >/dev/null 2>&1 || { echo "latex_test: SKIP (no python3)"; exit 77; }

fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/latex.XXXXXX")
# (LATEX_TEST_KEEP=1 keeps what was made, LATEX_TEST_V=1 says what is missing)
[ -z "$LATEX_TEST_KEEP" ] && trap 'rm -rf "$tmp"' EXIT
pass() { echo "PASS: $1"; }
failed() { echo "FAIL: $1"; fail=1; }

mkdir "$tmp/c" "$tmp/x"
cp tests/latex/paper.ms tests/latex/essay.ms tests/latex/works.bib "$tmp/c/"
cp examples/article.ms examples/memo.ms examples/chapter.ms examples/logic.ms \
    examples/maths.ms examples/chess.ms examples/works.bib "$tmp/x/"

# the documents, each with its classes: its directory and stem, book's
# options, then target=book2tex's options (+ for a space) ...
JOBS="
c paper -m article -S numeric -p works.bib | tex=-p+works.bib ieee=-c+ieee+-p+works.bib ieeeconf=-c+ieee,conference+-p+works.bib acm=-c+acm+-p+works.bib acmconf=-c+acm,sigconf+-p+works.bib
c essay -m article -S chicago -p works.bib | tex=-p+works.bib ad=-S+authordate+-p+works.bib
x article -m article -S numeric -p works.bib | tex=-p+works.bib
x memo -m memo -p works.bib | tex=-p+works.bib
x chapter -p works.bib | tex=-p+works.bib
x logic -p works.bib | tex=-p+works.bib
x maths -p works.bib | tex=-p+works.bib
x chess -p works.bib | tex=-p+works.bib
"
# troff's PDF of each, and its LaTeX for each class
cmds=""
echo "$JOBS" | while read -r d stem rest; do
    [ -z "$d" ] && continue
    bo=${rest%%|*}
    printf "cd '#U*%s'; book %s %s.ms >[2] %s.book.err\n" "$tmp/$d" "$bo" "$stem" "$stem"
    for t in ${rest#*|}; do
        tg=${t%%=*}
        o=$(echo "${t#*=}" | tr '+' ' ')
        printf "book2tex %s -o %s-%s.tex %s.ms >[2] %s-%s.err\n" "$o" "$stem" "$tg" "$stem" "$stem" "$tg"
    done
done > "$tmp/run.sh"
# (the Inferno shell's: one command a line, run in order)
with_timeout 900 "$EMU" -c1 -pheap=1024m -pmain=1024m -r"$ROOT" /dis/sh.dis "#U*$tmp/run.sh" </dev/null >"$tmp/emu.log" 2>&1

# each document's targets
targets() {
    echo "$JOBS" | while read -r d stem rest; do
        [ -z "$d" ] && continue
        for t in ${rest#*|}; do echo "$d $stem ${t%%=*}"; done
    done
}

# stage 1: book2tex said nothing (logic.ms's own macros and .if aside),
# and wrote a document
quiet=1
for j in $(targets | tr ' ' ':'); do
    d=${j%%:*}; r=${j#*:}; stem=${r%%:*}; tg=${r#*:}
    f="$tmp/$d/$stem-$tg"
    if [ ! -s "$f.tex" ] || ! grep -q 'end{document}' "$f.tex"; then
        failed "$stem for $tg: no LaTeX: $(cat "$f.err" 2>/dev/null | head -3)"; quiet=0; continue
    fi
    said=$(grep -v "macro tableau-\|\.if not written" "$f.err")
    [ -n "$said" ] && { failed "$stem for $tg: book2tex said: $said"; quiet=0; }
done
[ $quiet = 1 ] && pass "book2tex wrote each class's LaTeX, saying nothing"

# the LaTeX's structure against the source's
if python3 -I - "$tmp" <<'PY'
import re, sys, os
tmp = sys.argv[1]
bad = []
def src_counts(ms):
    s = open(ms, encoding='utf-8').read()
    c = {}
    c['section'] = len(re.findall(r'^\.section ', s, re.M))
    c['section*'] = len(re.findall(r'^\.section\* ', s, re.M))
    c['subsection'] = len(re.findall(r'^\.subsection ', s, re.M))
    c['figure'] = len(re.findall(r'^\.figure ', s, re.M)) + len(re.findall(r'^\.figure\* ', s, re.M))
    c['table'] = len(re.findall(r'^\.table ', s, re.M)) + len(re.findall(r'^\.table\* ', s, re.M))
    c['tag'] = len(re.findall(r'^\.EQ\s.*\(\S+\)\s*$', s, re.M))
    c['fn'] = len(re.findall(r'^\.fn', s, re.M))
    keys = set()
    for l in re.findall(r'^\.cite (.*)$', s, re.M):
        for p in l.split(';'):
            if p.strip(): keys.add(p.split()[0])
    c['keys'] = keys
    labels = set(re.findall(r'^\.(?:section|subsection|chapter|figure\*?|table\*?)\s+(?:"[^"]*"\s+)?(\S+)\s*$', s, re.M))
    c['labels'] = {l for l in labels if not l.startswith('"')}
    return c
for d in ('c', 'x'):
    for f in sorted(os.listdir(os.path.join(tmp, d))):
        if not f.endswith('.tex'): continue
        stem, tg = f[:-4].rsplit('-', 1)
        t = open(os.path.join(tmp, d, f), encoding='utf-8').read()
        body = re.sub(r'(?m)^%.*$', '', t)
        c = src_counts(os.path.join(tmp, d, stem + '.ms'))
        name = stem + ' for ' + tg
        def chk(what, got, want):
            if got != want: bad.append('%s: %s %s, the source %s' % (name, what, got, want))
        chk('sections', len(re.findall(r'\\section\{', body)), c['section'])
        chk('unnumbered sections', len(re.findall(r'\\section\*\{', body)), c['section*'])
        chk('subsections', len(re.findall(r'\\subsection\{', body)), c['subsection'])
        chk('figures', len(re.findall(r'\\begin\{figure\*?\}', body)), c['figure'])
        chk('tables', len(re.findall(r'\\begin\{table\*?\}', body)), c['table'])
        chk('numbered equations', len(re.findall(r'\\tag\{', body)), c['tag'])
        chk('notes', len(re.findall(r'\\footnote(?:text)?\{', body)), c['fn'])
        keys = set()
        for m in re.findall(r'\\(?:auto)?cites?(?:\[[^]]*\])?((?:\{[^}]*\}(?:\[[^]]*\])?)+)', body):
            for k in re.findall(r'\{([^}]*)\}', m):
                keys |= {x.strip() for x in k.split(',')}
        chk('works cited', sorted(keys), sorted(c['keys']))
        lab = set(re.findall(r'\\label\{([^}]*)\}', body))
        if not c['labels'] <= lab: bad.append(name + ': labels missing: ' + ' '.join(sorted(c['labels'] - lab)))
        envs = re.findall(r'\\(begin|end)\{([^}]*)\}', body)
        stack = []
        for be, e in envs:
            if be == 'begin': stack.append(e)
            elif not stack or stack.pop() != e: bad.append(name + ': \\end{%s} out of place' % e); break
        if stack: bad.append(name + ': not ended: ' + ' '.join(stack))
        depth = 0
        for ch in re.sub(r'\\[{}%$&#_]', '', body):
            depth += (ch == '{') - (ch == '}')
            if depth < 0: break
        if depth != 0: bad.append(name + ': braces unbalanced (%d)' % depth)
        if '\\begin{tabular}{' in body and re.search(r'\\begin\{tabular\}\{[^}]*\|', body) and 'vrules' not in open(os.path.join(tmp, d, stem + '.ms'), encoding='utf-8').read():
            bad.append(name + ': a tabular with vertical rules, none asked for')
for b in bad: print('    ' + b)
sys.exit(1 if bad else 0)
PY
then pass "every section, float, equation, note, label and citation once; environments and braces closed"
else failed "the LaTeX's structure"; fi

# for pdfLaTeX: nothing inputenc does not know, no character left out
if ! grep -l '\[U+' "$tmp"/c/*-ieee*.tex "$tmp"/c/*-acm*.tex >/dev/null 2>&1 &&
    grep -q 'ensuremath{\\in}' "$tmp/c/paper-ieee.tex" && grep -q 'ensuremath{\\mathbb{R}}' "$tmp/c/paper-ieee.tex" &&
    grep -q 'Gödel' "$tmp/c/paper-ieee.tex"; then
    pass "pdfLaTeX's characters: inputenc's, or commands (∈ ℝ as \\in \\mathbb{R}, Gödel as it is)"
else failed "pdfLaTeX's characters: $(grep -o '\[U+[0-9A-F]*\]' "$tmp"/c/*.tex | sort -u | head -5)"; fi

# the classes' conventions
p="$tmp/c/paper"
if grep -q '^\\documentclass\[journal\]{IEEEtran}' "$p-ieee.tex" &&
    grep -q '^\\documentclass\[conference\]{IEEEtran}' "$p-ieeeconf.tex" &&
    grep -q '\\bibliographystyle{IEEEtran}' "$p-ieee.tex" && grep -q 'begin{IEEEkeywords}' "$p-ieee.tex" &&
    grep -q 'thanks{Ada Typesetter is with InferNode Project' "$p-ieee.tex" &&
    grep -q 'IEEEauthorblockN{Zoë Compositor}' "$p-ieeeconf.tex" &&
    python3 -I - "$p-ieee.tex" <<'PY'
import re, sys
t = open(sys.argv[1], encoding='utf-8').read()
for m in re.finditer(r'\\begin\{table\}.*?\\end\{table\}', t, re.S):
    b = m.group(0)
    if b.find('\\caption') > b.find('\\begin{tabular}'): sys.exit(1)
PY
then pass "IEEEtran: journal and conference, its style, keywords, authors, tables' captions above"
else failed "IEEEtran's conventions"; fi
if grep -q '^\\documentclass\[acmsmall\]{acmart}' "$p-acm.tex" && grep -q '^\\documentclass\[sigconf\]{acmart}' "$p-acmconf.tex" &&
    grep -q '\\bibliographystyle{ACM-Reference-Format}' "$p-acm.tex" &&
    grep -q 'affiliation{\\institution{InferNode Project}\\city{Murray Hill}\\country{USA}}' "$p-acm.tex" &&
    grep -q '\\Description{' "$p-acm.tex" && grep -q '\\keywords{' "$p-acm.tex" &&
    [ "$(grep -n 'end{abstract}' "$p-acm.tex" | cut -d: -f1)" -lt "$(grep -n '^\\maketitle' "$p-acm.tex" | cut -d: -f1)" ]; then
    pass "acmart: its formats, style, affiliations (city, country), the abstract first, figures described"
else failed "acmart's conventions"; fi
if grep -q '^\\midrule$' "$p-tex.tex" && grep -q 'midrule\[\\heavyrulewidth\]' "$p-tex.tex" &&
    grep -q 'multicolumn{2}{c}{Time (s)}' "$p-tex.tex" &&
    grep -q 'usepackage\[style=numeric-comp,sorting=none,backend=biber\]{biblatex}' "$p-tex.tex" &&
    grep -q 'usepackage\[notes,backend=biber\]{biblatex-chicago}' "$tmp/c/essay-tex.tex" &&
    grep -q 'usepackage\[authordate,backend=biber\]{biblatex-chicago}' "$tmp/c/essay-ad.tex" &&
    grep -q '~\\autocite{ossanna1976},' "$p-tex.tex" && grep -qF "philosophy.''\\autocite[1]{anscombe1958}" "$tmp/c/essay-tex.tex" &&
    grep -qF 'see also \autocite[60--61]{macintyre1981}' "$tmp/c/essay-tex.tex"; then
    pass "LaTeX's article: booktabs' rules, spans; refer's styles as biblatex's; a number before the stop, a note after it, in a note a citation in its text"
else failed "LaTeX's article: tables, citations"; fi

# stage 2: set as a journal sets it
latexok=1
for t in pdflatex lualatex bibtex biber; do command -v $t >/dev/null 2>&1 || latexok=0; done
command -v kpsewhich >/dev/null 2>&1 && [ -n "$(kpsewhich IEEEtran.cls)" ] && [ -n "$(kpsewhich acmart.cls)" ] &&
    [ -n "$(kpsewhich biblatex-chicago.sty)" ] || latexok=0
if [ $latexok = 0 ]; then
    echo "latex_test: LaTeX not set (pdflatex, lualatex, bibtex, biber, IEEEtran, acmart, biblatex-chicago wanted)"
    exit $fail
fi
setok=1
for j in $(targets | tr ' ' ':'); do
    d=${j%%:*}; r=${j#*:}; stem=${r%%:*}; tg=${r#*:}
    (
        cd "$tmp/$d"
        f=$stem-$tg
        case $tg in
        ieee*|acm*) eng=pdflatex; bib=bibtex ;;
        *) eng=lualatex; bib=biber ;;
        esac
        $eng -interaction=nonstopmode -halt-on-error $f.tex >/dev/null 2>&1
        if grep -q '\\citation\|abx@aux@cite' $f.aux 2>/dev/null; then $bib $f >$f.blg.out 2>&1; fi
        $eng -interaction=nonstopmode -halt-on-error $f.tex >/dev/null 2>&1
        $eng -interaction=nonstopmode -halt-on-error $f.tex >/dev/null 2>&1
    )
    f="$tmp/$d/$stem-$tg"
    why=""
    grep -q '^!' "$f.log" && why="$why errors: $(grep -m2 '^!' "$f.log" | tr '\n' ' ')"
    grep -q 'undefined' "$f.log" && why="$why undefined: $(grep -m2 'undefined' "$f.log" | tr '\n' ' ')"
    grep -q 'Missing character' "$f.log" && why="$why $(grep -m1 'Missing character' "$f.log")"
    if [ -f "$f.bbl" ]; then
        n=$(grep -c '\\bibitem\|\\entry{' "$f.bbl")
        k=$(grep -o '\\\(auto\)\?cites\?\(\[[^]]*\]\)\?{[^}]*}' "$f.tex" | sed 's/.*{//; s/}//' | tr ',' '\n' | sort -u | grep -c .)
        [ "$n" -lt "$k" ] && why="$why the bibliography $n works of $k cited"
    fi
    [ -s "$f.pdf" ] || why="$why no PDF"
    [ -n "$why" ] && { failed "$stem for $tg:$why"; setok=0; }
done
[ $setok = 1 ] && pass "each class set: no error, nothing undefined, no character missing, every work in the bibliography"

# stage 3: what troff set, LaTeX set
if command -v pdftotext >/dev/null 2>&1; then
    if LATEX_TEST_V=$LATEX_TEST_V python3 -I - "$tmp" <<'PY'
import re, subprocess, sys, os, unicodedata
from collections import Counter
tmp = sys.argv[1]
# words the classes word otherwise, or set as their own
OWN = set('references reference keywords abstract figure fig table index terms'.split())
# the text of a PDF (up to its references), running heads and folios
# (lines on two pages or more, but the first) left out, hyphens at
# lines' ends joined
def text(p, cut=True):
    t = subprocess.run(['pdftotext', p, '-'], capture_output=True, text=True).stdout
    pages = t.split('\f')
    # (a running head is the same line but its folio: 2 CHAPTER 1. ...)
    key = lambda l: re.sub(r'\s+', ' ', re.sub(r'\d', '', l)).strip() if re.search(r'[^\W\d_]{2}', l) else l.strip()
    seen = Counter()
    for pg in pages:
        for l in set(key(x) for x in pg.split('\n')):
            if l: seen[l] += 1
    out = []
    for k, pg in enumerate(pages):
        ls = [l for l in pg.split('\n') if k == 0 or not (seen[key(l)] >= 2 and len(l.strip()) < 70)]
        # (and LaTeX's book's heads, though a short chapter has each once:
        # CHAPTER 1. THE NORMAL LAW, 1.2. SUMS OF ERRORS)
        ls = [l for l in ls if not re.fullmatch(r'\s*(CHAPTER \d+\.|\d+(\.\d+)+\.)\s+[^a-z]+', l)]
        # (mathematics' letters, read in another order, left out; troff's
        # ^ is the circumflex, U+02C6)
        t = re.sub('[\U0001D400-\U0001D7FF]', ' ', '\n'.join(ls))
        out.append(unicodedata.normalize('NFKC', t).replace('\u02c6', '^'))
    s = '\n'.join(out)
    s = re.sub('(\\w)[-\u00ad\u2010]\n(\\w)', '\\1\\2', s)
    # small capitals (IEEE's headings) read as I NTRODUCTION
    s = re.sub(r'\b([A-Z]) ([A-Z]{2,})\b', r'\1\2', s)
    m = list(re.finditer(r'(?m)^\s*(?:[IVX]+\.\s*)?(References|REFERENCES|Bibliography)\s*$', s))
    if m and cut:
        s = s[:m[-1].start()]
    # acmart's own: its rights, its form of reference, the addresses
    s = re.sub(r'(?s)Permission to make digital.*?nnnnnnn\.nnnnnnn', ' ', s)
    s = re.sub(r'(?s)ACM Reference Format:.*?nnnnnnn\.nnnnnnn', ' ', s)
    s = re.sub(r"(?s)Authors' addresses:.*?\.\n\n", ' ', s)
    return s
# its words, and its numbers with decimal points (a table's), but
# headings' (2.1 Equations: IEEE's are A. Equations)
def words(s):
    s = re.sub(r'(?m)^(\d+\.)+\d+[ \t]+(?=[A-Z])', ' ', s)
    return [w.lower() for w in re.findall(r"[^\W\d_]{2,}|\d+\.\d+", s)]
bad = []
for d, stem, tg in [('c','paper','tex'), ('c','paper','ieee'), ('c','paper','ieeeconf'), ('c','paper','acm'),
        ('c','paper','acmconf'), ('c','essay','tex'), ('x','article','tex'), ('x','memo','tex'),
        ('x','chapter','tex'), ('x','logic','tex'), ('x','maths','tex'), ('x','chess','tex')]:
    tr = os.path.join(tmp, d, stem + '.pdf'); lx = os.path.join(tmp, d, '%s-%s.pdf' % (stem, tg))
    if not os.path.exists(tr) or not os.path.exists(lx):
        bad.append('%s for %s: no PDF to compare' % (stem, tg)); continue
    a = words(text(tr))
    lt = text(lx)
    b = words(lt)
    ball = words(text(lx, False))
    # a word troff set is in LaTeX's if one of the three runs of three
    # words it is in is, anywhere (a float may have gone after the
    # references); or, read in another order (a table's cells, a title's
    # authors, a display's lines), if LaTeX set it as often before them
    # (as many times: a run troff set more often than LaTeX vouches for
    # none of its words)
    tri = Counter(zip(ball, ball[1:], ball[2:]))
    atri = Counter(zip(a, a[1:], a[2:]))
    na, nb = Counter(a), Counter(b)
    # (a picture's words, which troff's PDF has where the picture's
    # labels are, are the picture's PDF's, included whole)
    npic = Counter()
    for f in os.listdir(os.path.join(tmp, d)):
        if f.startswith('%s-%s-pic' % (stem, tg)) and f.endswith('.pdf'):
            npic += Counter(words(subprocess.run(['pdftotext', os.path.join(tmp, d, f), '-'], capture_output=True, text=True).stdout))
    miss = []
    for i, w in enumerate(a):
        if w in OWN:
            continue
        if not any(i + k >= 0 and i + k + 2 < len(a) and tri[tuple(a[i + k:i + k + 3])] >= atri[tuple(a[i + k:i + k + 3])] for k in (-2, -1, 0)):
            if nb[w] + npic[w] < na[w]:
                miss.append(w)
    # a word hyphenated across a float (de- ... ontic) is two
    whole = set(ball)
    for w in list(miss):
        for v in list(miss):
            if v != w and w + v in whole and w in miss and v in miss:
                miss.remove(w)
                miss.remove(v)
    if os.environ.get('LATEX_TEST_V'):
        print('    %s for %s: %d of %d words not in order: %s' % (stem, tg, len(miss), len(a), ' '.join(miss)))
    if miss:
        bad.append('%s for %s: %d of %d words missing: %s' % (stem, tg, len(miss), len(a), ' '.join(miss)[:300]))
    full = subprocess.run(['pdftotext', lx, '-'], capture_output=True, text=True).stdout.replace('\n', ' ')
    if stem == 'paper' and tg in ('tex',):
        for w in ['Gödel', 'Łukasiewicz', 'Erdős', 'Dvořák', 'Søren', 'Ångström', '50% of $3', 'item #4',
                  'snake_case', '{braces}', 'back\\slash', '1984–1994']:
            if w not in full: bad.append('%s for %s: %r not set' % (stem, tg, w))
    if stem == 'paper' and tg != 'tex':
        # (pdfLaTeX's T1 fonts build ő and ř of an accent and a letter,
        # which pdftotext reads as two: the LaTeX has them as written)
        src = open(lx[:-4] + '.tex', encoding='utf-8').read()
        for w in ['Gödel', 'Łukasiewicz', 'Erdős', 'Dvořák', 'Søren', 'Ångström']:
            if w not in src: bad.append('%s for %s: %r not written' % (stem, tg, w))
        for w in ['Gödel', 'Łukasiewicz', 'Søren', 'Ångström', '50% of $3', 'item #4', 'snake_case', '{braces}', 'back\\slash']:
            if w not in full: bad.append('%s for %s: %r not set' % (stem, tg, w))
    if stem == 'essay':
        for w in ['ἀρετή', 'ἕξις', 'Faculté', 'Łukasiewicz']:
            if w not in full: bad.append('%s for %s: %r not set' % (stem, tg, w))
for b in bad: print('    ' + b)
sys.exit(1 if bad else 0)
PY
    then pass "every word troff set, LaTeX set; accents and special characters as written"
    else failed "the words of troff's PDF and LaTeX's"; fi
fi

exit $fail
