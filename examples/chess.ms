.\" chess.ms — chess diagrams with chess(1): a position given in
.\" Forsyth-Edwards notation between .CB and .CE, moves in the text in
.\" figurine notation (♘f3).
.\"
.\"	book chess.ms		# chess.pdf
.chapter "Chess at Bell Labs" chess
.epigraph
When in doubt, use brute force.
.attrib "Ken Thompson"
.endepigraph

The building in Murray Hill where Unix was written, and where troff
first set a page, also played chess. Ken Thompson and Joe Condon built
Belle there, a machine whose move generator and evaluation were wired
in hardware; it searched some hundred thousand positions a second, won
the World Computer Chess Championship in 1980, and in 1983 became the
first machine to earn a master's rating.
.section "The endgame by retrograde analysis" endgame

Thompson's lasting contribution to chess was not Belle's play but its
endgames. With few pieces on the board, every position can be listed.
Beginning from the mates, a program works backwards: a position from
which the side to move can reach a mate is won, one from which every
move reaches a won position for the opponent is lost, and so on until
nothing changes. What remains is drawn. The result is perfect play,
and it overturned a good deal of received theory.
.p
Queen against rook was among the first endings so solved. The queen
wins, and every textbook says so; but the defence is
stubborn, and the winning method long. When a grandmaster undertook to
win such positions against the machine, the rook proved far harder to
catch than he had expected, the machine finding at each move the
defence that held out longest. Later databases of five pieces showed
endings long thought drawn to be won, in more moves than the rules
then allowed, and the fifty-move rule was for a time given
exceptions.
.CB
fen 3k4/8/3K4/8/8/8/2r5/7Q w
.CE
.section "A game in the old style" opera

Played in a box at the Paris opera in 1858, between Paul Morphy and
two amateurs in consultation, the Duke of Brunswick and Count
Isouard, it is the most often shown game of chess, for it shows in
seventeen moves why development matters.
.p
.ti 0
\fB1.e4 e5 2.♘f3 d6 3.d4 ♗g4\fP
.br
The pin is premature; White can break it at once.
.br
\fB4.dxe5 ♗xf3 5.♕xf3 dxe5 6.♗c4 ♘f6 7.♕b3 ♕e7\fP
.CB
fen rn2kb1r/ppp1qppp/5n2/4p3/2B1P3/1Q6/PPP2PPP/RNB1K2R w
.CE
Black has surrendered the bishop pair and the centre. White's queen
and bishop bear down on f7, and the queen on b7 as well.
.br
\fB8.♘c3\fP
.br
Morphy develops rather than take the pawn: 8.♕xb7 ♕b4+ would force
the queens off.
.br
\fB8.\|.\|.\~c6 9.♗g5 b5 10.♘xb5 cxb5 11.♗xb5+ ♘bd7 12.0-0-0
♖d8\fP
.br
White has given a knight to open the lines; every piece is now in
play, and Black's king is still in the centre.
.CB
fen 3rkb1r/p2nqppp/5n2/1B2p1B1/4P3/1Q6/PPP2PPP/2KR3R w
.CE
\fB13.♖xd7 ♖xd7 14.♖d1 ♕e6 15.♗xd7+ ♘xd7\fP
.br
White to move mates in two.
.br
\fB16.♕b8+! ♘xb8 17.♖d8#\fP
.CB
fen 1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b
.CE
The rook mates on d8, defended by the bishop on g5. White mates with
only a rook and a bishop left, against Black's queen, rook, bishop and
knight.
