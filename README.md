# troff for InferNode

A typesetting system for books, for [InferNode](https://github.com/infernode-os/infernode):
troff and its preprocessors (eqn, tbl, pic, refer), PDF output (tr2pdf),
macro packages for books (`-mbook`), papers (`-ms`) and manual pages
(`-man`), an index maker, a LaTeX converter, and the Libertinus fonts.

This is an add-on, not a copy of InferNode. It changes nothing in
InferNode: it is built into its own `dis/`, and put into a name space
by binding its directories after InferNode's own.

Tested in Xenith.app 0.8.0. It needs InferNode from 14 October 2026 or later
(`af0acc617`): Xenith's document engine interface, `docengine(2)`,
gained `pinned` and `viewing` then.

## Build

The build is InferNode's `mk`: a top-level `mkfile` runs `mk` in each
of the package's directories, with InferNode's `mkconfig` and
`mksubdirs`. It needs InferNode's host `mk` and `limbo` on the path
(`$ROOT/<OS>/<arch>/bin` of a built InferNode tree; on a Mac with
plan9port, put InferNode's ahead of plan9port's `mk`), and `ROOT` set
to the InferNode the package is to run in:

    git clone https://github.com/pdfinn/infernode-troff troffpkg
    cd troffpkg
    PATH=/path/to/infernode/MacOSX/arm64/bin:$PATH
    mk ROOT=/path/to/infernode install

`ROOT` gives the build InferNode's modules (`$ROOT/module`) and its
`mkconfig`; nothing is written there. To run in Xenith.app, build
against the app's own tree, with the tools from any InferNode tree:

    mk ROOT=/Applications/Xenith.app/Contents/Resources install

After InferNode changes a module the package uses, build again from
clean: `mk nuke` and `mk install`.

## Put it in the name space

`troffns` is an InferNode shell script that binds each of the
package's directories after InferNode's (`bind -a`): commands in
`/dis`, macros and device descriptions in `/lib/tmac` and `/lib/troff`,
fonts in `/fonts/libertinus`, pages in `/man`. Nothing of InferNode's is
hidden, and nothing on disk changes: the binds are in the name space of
the shell that runs it, and of what that shell starts. Run it with `run`
(not as a command, whose binds would end with it), giving it the
package's directory as InferNode sees it. A host directory is under
`#U*`:

    run '#U*/path/to/troffpkg/troffns' '#U*/path/to/troffpkg'

For every shell, put that line in the profile the shell runs at start.

A directory InferNode does not have is not bound, since there is
nothing to bind it after. Xenith.app has no `/man`, so there the pages
are read from the package: `troff -man '#U*/path/to/troffpkg/man/1/troff'`.

## Xenith

Xenith shows troff output (`x T` in its first bytes) as a document, and
troff source (`.ms`, `.man`, ...) with Render, through the engine
`dis/xenith/doc/trodoc.dis`. Xenith finds engines through
`/lib/xenith/doctypes`, which is InferNode's; add these two lines to it:

    troff	binary	/dis/xenith/doc/trodoc.dis	magic=x\x20T\x20
    roff	source	/dis/xenith/doc/trodoc.dis	.ms .mm .me .man .roff .tr .t

Xenith keeps the name space it starts with, and a command run from it
cannot change that. So `troffns` must run before Xenith starts, in the
shell that starts it: in a development tree, the profile; in Xenith.app,
whose profile (`lib/sh/profile`) and start (`lib/xen/boot.sh`) are in the
app and have no place for a user's own, those files in the app, which
an update of the app replaces.

## Use

    book -p works.bib book.ms               # book.pdf
    troff -ms paper.ms | tr2pdf >paper.pdf
    troff -man /man/1/troff | tr2pdf >troff.pdf

`man troff`, `man book` and `man 6 troff` describe it all;
`docs/TROFF.md` is the design.

## Not yet

- The tests in `tests/` were written to run inside an InferNode tree
  and have not yet been made to run against the package.

## Licence

MIT (`LICENSE`). The programs translated from Neatroff, Neateqn,
Neatrefer, Neatpost and Neatmkfn (Ali Gholami Rudi, ISC) and from Plan 9's
tbl and pic keep their notices in their sources; the macros' are in
`lib/tmac/NOTICE`, the hyphenation patterns' in `lib/troff/hyph/NOTICE`,
the fonts' in `fonts/libertinus/OFL.txt`.
