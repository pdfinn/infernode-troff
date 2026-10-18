.\" logic.ms — logic set with eqn, tbl and pic: formulas in the text,
.\" a truth table, and proofs by tableau (truth trees), with the
.\" countermodels open branches describe. The tableaux and countermodels are
.\" tableau(1)'s, from infernode-wwb (prove -P, then tableau), each
.\" tree made a figure, its title a caption, and figure 1.3's
.\" countermodel drawn beside its tree rather than as a table below.
.\"
.\"	book logic.ms		# logic.pdf
.char → \f[S]\N'arrowright'
.char ↔ \f[S]\N'arrowboth'
.char ∧ \f[S]\N'logicaland'
.char ∨ \f[S]\N'logicalor'
.char ¬ \f[S]\N'logicalnot'
.char ∀ \f[S]\N'universal'
.char ∃ \f[S]\N'existential'
.char ◇ \f[S]\N'uni25C7'
.char × \f[S]\N'multiply'
.char ∅ \f[S]\N'emptyset'
.char ↑ \f[S]\N'arrowup'
.rules 1
.fp 13 SZ S
.fzoom SZ 1333
.char □ \v'0.072m'\f[SZ]\N'H22073'\v'-0.072m'
.de tableau-hd
'sp |1i
..
.de tableau-fo
'bp
..
.if !\n[book-ps] .wh 0 tableau-hd
.if !\n[book-ps] .wh -1i tableau-fo
.if !\n[book-ps] .ps 11
.if !\n[book-ps] .vs 14
.EQ
delim $$
chartype bin "∧"
chartype bin "∨"
chartype bin "→"
chartype bin "↔"
chartype punct ","
.EN
.char ⊢ \f[S]\N'uni22A2'
.chapter "Proof by Tableau" logic
.epigraph
If controversies were to arise, there would be no more need of
disputation between two philosophers than between two accountants.
For it would suffice to take their pencils in their hands, and say to
each other: Let us calculate.
.attrib "Leibniz"
.endepigraph

An argument is valid when its conclusion cannot be false while its
premises are true. For a few propositional letters the definition can
be checked by brute force: list every way of making the letters true
or false, and look for a row where every premise is true and the
conclusion false. There is no such row for modus ponens, from
$p → q$ and $p$ to $q$:
.TS
center;
c c | c c | c
c c | c c | c.
$p$	$q$	$p → q$	$p$	$q$
_
T	T	T	T	T
T	F	F	T	F
F	T	T	F	T
F	F	T	F	F
.TE
.p
The table doubles with every letter, and says nothing about necessity
or obligation, where a sentence's truth depends on other worlds than
this one. A tableau, or truth tree, does better. Suppose the premises
true and the conclusion false, and take the formulas apart by their
connectives: $A ∧ B$ puts both $A$ and $B$ on the branch, while
$A ∨ B$ and $A → B$ split it in two. A branch holding a formula and
its negation is closed ($times$): no way of making things true lies
along it. If every branch closes, the supposition was impossible and
the argument is valid. A branch that stays open describes a
counterexample.
.section "Modus ponens" mp

Here is modus ponens again, as a tableau, with a third premise, that
it is cold, which the proof never uses. Denying the conclusion (line
3) and splitting the conditional (line 1) closes both branches at
once (figure \*[ref mp]).
.figure mp
.alt "A tableau for modus ponens: 1. rain → wet, P1. 2. rain, P2. 3. ¬wet, C denied. It branches in two, by 1 →. Branch 1: 4. ¬rain. Closed by 2, 4. Branch 2: 5. wet. Closed by 3, 5. "
.PS
"\s-11.\s0" rjust at (0.603,0.000)
"$ roman \&rain → roman \&wet $" ljust at (0.673,0.000)
"\s-1P1\s0" ljust at (1.659,0.000)
"\s-12.\s0" rjust at (0.603,-0.215)
"$ roman \&rain $" ljust at (0.673,-0.215)
"\s-1P2\s0" ljust at (1.659,-0.215)
"\s-13.\s0" rjust at (0.603,-0.430)
"$¬ roman \&wet $" ljust at (0.673,-0.430)
"\s-1C denied\s0" ljust at (1.659,-0.430)
"\s-11 →\s0" ljust at (1.659,-0.692)
line from (1.016,-0.548) to (0.336,-0.868)
"\s-14.\s0" rjust at (0.095,-0.986)
"$¬ roman \&rain $" ljust at (0.165,-0.986)
"$times$ \s-12, 4\s0" ljust at (0.165,-1.202)
line from (1.016,-0.548) to (1.577,-0.868)
"\s-15.\s0" rjust at (1.352,-0.986)
"$ roman \&wet $" ljust at (1.422,-0.986)
"$times$ \s-13, 5\s0" ljust at (1.422,-1.202)
.PE
.caption "Modus ponens, by tableau: both branches close. The premise that it is cold (P3) is never used."
.endfigure
.section "Necessity" necessity

Modal logic reads $□ A$ as \(lqnecessarily $A$\(rq and $◇ A$ as
\(lqpossibly $A$\(rq. Following Kripke, a model is a set of worlds
and a relation $roman R$ of accessibility between them: $□ A$ is true
at a world when $A$ is true at every world it sees, and $◇ A$ when $A$
is true at some world it sees. Each formula in a tableau is now true
at a world, $w sub 0$ to begin with. A $◇$ opens a new world, and a
$□$ sends its formula along every arrow already drawn. The axiom of
the weakest normal logic, K, is that necessity distributes over the
conditional:
.EQ
□ ( p → q ) , ~ □ p ~ ⊢ ~ □ q
.EN
Its tableau (figure \*[ref axk]) needs one new world, $w sub 1$, and
closes on both branches there.
.figure axk
.alt "A tableau for axiom K: 1. □(p → q), w0, P1. 2. □p, w0, P2. 3. ¬□q, w0, C denied. 4. ◇¬q, w0, 3 ¬□. 5. w0 R w1, 4 ◇. 6. ¬q, w1, 4 ◇. 7. p → q, w1, 1 □. 8. p, w1, 2 □. It branches in two, by 7 →. Branch 1: 9. ¬p, w1. Closed by 8, 9. Branch 2: 10. q, w1. Closed by 6, 10. "
.PS
"\s-11.\s0" rjust at (0.642,0.000)
"$□ (  p → q  )  ,  w sub 0 $" ljust at (0.712,0.000)
"\s-1P1\s0" ljust at (1.790,0.000)
"\s-12.\s0" rjust at (0.642,-0.215)
"$□ p  ,  w sub 0 $" ljust at (0.712,-0.215)
"\s-1P2\s0" ljust at (1.790,-0.215)
"\s-13.\s0" rjust at (0.642,-0.430)
"$¬□ q  ,  w sub 0 $" ljust at (0.712,-0.430)
"\s-1C denied\s0" ljust at (1.790,-0.430)
"\s-14.\s0" rjust at (0.642,-0.645)
"$◇¬ q  ,  w sub 0 $" ljust at (0.712,-0.645)
"\s-13 ¬□\s0" ljust at (1.790,-0.645)
"\s-15.\s0" rjust at (0.642,-0.860)
"$ w sub 0  ~roman R~  w sub 1 $" ljust at (0.712,-0.860)
"\s-14 ◇\s0" ljust at (1.790,-0.860)
"\s-16.\s0" rjust at (0.642,-1.075)
"$¬ q  ,  w sub 1 $" ljust at (0.712,-1.075)
"\s-14 ◇\s0" ljust at (1.790,-1.075)
"\s-17.\s0" rjust at (0.642,-1.290)
"$ p → q  ,  w sub 1 $" ljust at (0.712,-1.290)
"\s-11 □\s0" ljust at (1.790,-1.290)
"\s-18.\s0" rjust at (0.642,-1.505)
"$ p  ,  w sub 1 $" ljust at (0.712,-1.505)
"\s-12 □\s0" ljust at (1.790,-1.505)
"\s-17 →\s0" ljust at (1.790,-1.767)
line from (1.101,-1.623) to (0.357,-1.943)
"\s-19.\s0" rjust at (0.095,-2.062)
"$¬ p  ,  w sub 1 $" ljust at (0.165,-2.062)
"$times$ \s-18, 9\s0" ljust at (0.165,-2.276)
line from (1.101,-1.623) to (1.715,-1.943)
"\s-110.\s0" rjust at (1.457,-2.062)
"$ q  ,  w sub 1 $" ljust at (1.527,-2.062)
"$times$ \s-16, 10\s0" ljust at (1.527,-2.276)
.PE
.caption "Axiom K in the logic K: $□ ( p → q ) , ~ □ p ~ ⊢ ~ □ q$."
.endfigure
.section "When a branch stays open" open

What is necessary is surely possible, yet in K $◇ p$ does not follow
from $□ p$. Denying $◇ p$ gives $□ ¬ p$, no rule of K applies to boxes
alone, and the branch stays open ($↑$). Read off, it is a countermodel:
one world that sees none, where every $□$ is true and every $◇$ false
(figure \*[ref dk]).
.figure dk
.alt "A tableau for necessarily p, so possibly p, in K, not valid (a branch stays open): 1. □p, w0, P1. 2. ¬◇p, w0, C denied. 3. □¬p, w0, 2 ¬◇. Open. Its countermodel: one world, w0, where p is false and which sees no world."
.PS
"\s-11.\s0" rjust at (0.095,0.000)
"$□ p  ,  w sub 0 $" ljust at (0.165,0.000)
"\s-1P1\s0" ljust at (0.966,0.000)
"\s-12.\s0" rjust at (0.095,-0.215)
"$¬◇ p  ,  w sub 0 $" ljust at (0.165,-0.215)
"\s-1C denied\s0" ljust at (0.966,-0.215)
"\s-13.\s0" rjust at (0.095,-0.430)
"$□¬ p  ,  w sub 0 $" ljust at (0.165,-0.430)
"\s-12 ¬◇\s0" ljust at (0.966,-0.430)
"$↑$" ljust at (0.165,-0.645)
line from (1.750,0.130) to (2.550,0.130)
"$ w sub 0 $" at (2.350,0.000)
line from (1.750,-0.110) to (2.550,-0.110)
"$ p $" ljust at (1.750,-0.250)
"F" at (2.350,-0.250)
"$roman R ( w )$" ljust at (1.750,-0.465)
"$∅$" at (2.350,-0.465)
line from (1.750,-0.590) to (2.550,-0.590)
.PE
.caption "From $□ p$ to $◇ p$ in K: an open branch, and its countermodel."
.endfigure
.section "Obligation" obligation

The cure is to require that every world see at least one world: that
the relation be serial. This is the logic KD, and its rule D draws a
new world where none is there. Read $□$ as \(lqit ought to be that\(rq
and $◇$ as \(lqit is permitted that\(rq, written O and P, and KD
becomes the standard deontic logic, the logic of obligation that von
Wright set out in 1951. The worlds are now the ideal ones, those in
which everything obligatory is done, and seriality says that there is
always at least one: no code of conduct demands the impossible. Its
axiom is that what is obligatory is permitted, and now the tree closes
(figure \*[ref kd]).
.figure kd
.alt "A tableau for O p, so P p, in KD: 1. O p, w0, P1. 2. ¬P p, w0, C denied. 3. O ¬p, w0, 2 ¬P. 4. w0 R w1, D. 5. p, w1, 1 O. 6. ¬p, w1, 3 O. Closed by 5, 6. "
.PS
"\s-11.\s0" rjust at (0.095,0.000)
"$ roman O ^  p  ,  w sub 0 $" ljust at (0.165,0.000)
"\s-1P1\s0" ljust at (0.982,0.000)
"\s-12.\s0" rjust at (0.095,-0.215)
"$¬ roman P ^  p  ,  w sub 0 $" ljust at (0.165,-0.215)
"\s-1C denied\s0" ljust at (0.982,-0.215)
"\s-13.\s0" rjust at (0.095,-0.430)
"$ roman O ^ ¬ p  ,  w sub 0 $" ljust at (0.165,-0.430)
"\s-12 ¬P\s0" ljust at (0.982,-0.430)
"\s-14.\s0" rjust at (0.095,-0.645)
"$ w sub 0  ~roman R~  w sub 1 $" ljust at (0.165,-0.645)
"\s-1D\s0" ljust at (0.982,-0.645)
"\s-15.\s0" rjust at (0.095,-0.860)
"$ p  ,  w sub 1 $" ljust at (0.165,-0.860)
"\s-11 O\s0" ljust at (0.982,-0.860)
"\s-16.\s0" rjust at (0.095,-1.075)
"$¬ p  ,  w sub 1 $" ljust at (0.165,-1.075)
"\s-13 O\s0" ljust at (0.982,-1.075)
"$times$ \s-15, 6\s0" ljust at (0.165,-1.290)
.PE
.caption "From O $p$ to P $p$ in KD: the rule D draws $w sub 1$, and the tree closes."
.endfigure
.p
The same logic proves things that sound wrong. From O $p$ it gives
O $( p ∨ q )$: if I ought to post the letter, then I ought to post it
or burn it. This is Ross's paradox, and it is valid in KD, because
every ideal world in which the letter is posted is one in which it is
posted or burnt. Whether that shows the logic wrong or the English
misleading is still argued; the tree only shows what the logic says.
.section "Trees by machine" machine

The method is mechanical, which is its point. Beth and Hintikka gave it
in the 1950s and Smullyan made it standard in \fIFirst-Order Logic\fP
(1968): every rule takes a formula apart into smaller ones, so for the
propositional logics, and with the proper care for K and KD, a tree
always ends, and the method decides validity. For the full logic of
quantifiers no method can, as Church and Turing showed in 1936, and a
tree may grow without end.
.p
The trees in this chapter were found by a program and drawn by
another: \f[CR]prove\fP searched for each one, and \f[CR]tableau\fP
set it out as pic, its formulas in eqn and its countermodels as tables,
for troff to set. Each figure is described in words in the PDF, line
by line, for a reader who hears it rather than sees it.
.p
The use of such a program is in checking arguments written in prose.
Told that the code was audited, and the audit found no bugs, so the
code is safe to deploy, \f[CR]prove\fP finds the tree of figure
\*[ref gap] open. Nothing in the premises speaks of safety at all, and
the open branch, read off, is the case the writer passed over: code
audited, no bugs found, and still not safe. The program says what
would close the gap, a premise that what is audited is safe or that
what has no bugs found is, and leaves the writer to say whether either
is true.
.figure gap
.alt "A tableau for the argument that the audited code is safe, not valid (a branch stays open): 1. audited ∧ nobugs, P1. 2. ¬safe, C denied. 3. audited, 1 ∧. 4. nobugs, 1 ∧. Open: audited = T, nobugs = T, safe = F. "
.PS
"\s-11.\s0" rjust at (0.095,0.000)
"$ roman \&audited ∧ roman \&nobugs $" ljust at (0.165,0.000)
"\s-1P1\s0" ljust at (1.545,0.000)
"\s-12.\s0" rjust at (0.095,-0.215)
"$¬ roman \&safe $" ljust at (0.165,-0.215)
"\s-1C denied\s0" ljust at (1.545,-0.215)
"\s-13.\s0" rjust at (0.095,-0.430)
"$ roman \&audited $" ljust at (0.165,-0.430)
"\s-11 ∧\s0" ljust at (1.545,-0.430)
"\s-14.\s0" rjust at (0.095,-0.645)
"$ roman \&nobugs $" ljust at (0.165,-0.645)
"\s-11 ∧\s0" ljust at (1.545,-0.645)
"$↑ ~ roman \&audited  = roman T , roman \&nobugs  = roman T , roman \&safe  = roman F$" ljust at (0.165,-0.860)
.PE
.caption "The audited code is safe to deploy? The tree stays open, and its last line is the countermodel: audited and no bugs found, yet not safe."
.endfigure
