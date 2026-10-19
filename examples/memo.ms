.\" memo.ms — a technical memorandum for -mmemo: the head (subject, date,
.\" authors, number), the kind of memorandum, numbered sections, a table,
.\" the authors' names at the end.
.\"
.\"	book -m memo memo.ms		# memo.pdf
.org "Example Laboratories"
.title "Balancing the Last Page of a Two-Column Article"
.date "October 19, 2026"
.author "A. Typesetter" "Room 2C-518" "x6021"
.author "B. Compositor" "Room 2C-521" "x6044"
.case "2026-14"
.file "2026-14-3"
.number "TM 26-1014-1"
.abstract
The last page of an article set in two columns is balanced: its first
column ends at half the height of its text, so that both end level.
The height is measured on one pass and used on the next.
.endabstract
.section "The problem" problem

Troff sets a page's columns one after the other: the first until it is
full, then the second. On the last page of an article the text may
fill the first column and only a few lines of the second, which looks
unfinished, and journals do not print pages so.
.section "The method" method

The height of the text on the last page is not known until it has been
set. The macros record it, at the end of the document, in the file of
cross-references that the book command already reads on the next pass.
On that pass, when the last page begins, the first column's foot is
moved to half the recorded height, rounded up to a whole line, and the
second column takes the rest.
.p
A page balanced so would measure differently on the next pass, since
the first column now ends early. The height is therefore recorded once,
from the page as it was set unbalanced, and kept on later passes; the
passes then agree, and the command stops.
.section "Results" results

On the example article distributed with the macros, and on a generated
one of six pages with notes and figures in both columns, the last
page's columns end within a line or two of each other, and no word of
the text overlaps another.
.TS
center;
l n n.
document	pages	words overlapping
_
article.ms	2	0
generated	6	0
.TE
.signature
