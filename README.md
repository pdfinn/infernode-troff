# troff for InferNode

A typesetting system for books, for [InferNode](https://github.com/infernode-os/infernode):
troff and its preprocessors (eqn, tbl, pic, refer), PDF output (tr2pdf),
macro packages for books (`-mbook`), papers (`-ms`) and manual pages
(`-man`), an index maker, a LaTeX converter, and the Libertinus fonts.

This is an add-on, not a copy of InferNode. It needs an InferNode
checkout to build and to run in, and changes nothing in it: it is built
into its own `dis/`, and put into a name space by binding its
directories after InferNode's own.

Tested against InferNode at `4a35c2e91` (13 October 2026).

## Install

From the host, with InferNode built (its `mk` and `limbo` in
`$ROOT/<OS>/<arch>/bin`):

    git clone https://github.com/pdfinn/InferNode-troff troffpkg
    troffpkg/build.sh /path/to/infernode

Then, inside InferNode, put it into the name space:

    run '#U*/path/to/troffpkg/troffns' '#U*/path/to/troffpkg'

(or bind it somewhere first and use that: `bind '#U*/path/to/troffpkg' /n/troff`,
then `run /n/troff/troffns /n/troff`). To have it in every session, put
that line in your `lib/profile`. `troffns` binds each of the package's
directories after InferNode's (`bind -a`): commands in `/dis`, macros
and device descriptions in `/lib/tmac` and `/lib/troff`, fonts in
`/fonts/libertinus`, pages in `/man`. Nothing of InferNode's is hidden.

## Use

    book -p works.bib book.ms               # book.pdf
    troff -ms paper.ms | tr2pdf >paper.pdf
    troff -man /man/1/troff | tr2pdf >troff.pdf

`man troff`, `man book` and `man 6 troff` describe it all;
`docs/TROFF.md` is the design.

## Not yet

- Xenith's document view of troff's output (`dis/xenith/doc/trodoc.dis`,
  built here) is found through `/lib/xenith/doctypes`, one file in
  InferNode. To use it, add these two lines to that file:

      troff	binary	/dis/xenith/doc/trodoc.dis	magic=x\x20T\x20
      roff	source	/dis/xenith/doc/trodoc.dis	.ms .mm .me .man .roff .tr .t

- The tests in `tests/` were written to run inside an InferNode tree
  and have not yet been made to run against the package.

## Licence

MIT (`LICENSE`). The programs translated from Neatroff, Neateqn,
Neatrefer, Neatpost and Neatmkfn (Ali Gholami Rudi, ISC) and from Plan 9's
tbl and pic keep their notices in their sources; the macros' are in
`lib/tmac/NOTICE`, the hyphenation patterns' in `lib/troff/hyph/NOTICE`,
the fonts' in `fonts/libertinus/OFL.txt`.
