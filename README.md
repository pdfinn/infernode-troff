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

## Installing

You need a built InferNode, since the package is built with its `mk`
and `limbo`. On the host:

```sh
git clone https://github.com/pdfinn/infernode-troff troffpkg
cd troffpkg
export ROOT=/path/to/infernode
export PATH=$ROOT/MacOSX/arm64/bin:$PATH   # or Linux/amd64, and so on
mk install
```

This builds into `dis/` inside this tree. Nothing is copied into
InferNode: `ROOT` gives the build InferNode's `mkconfig` and modules
(`$ROOT/module`), and nothing is written there. On a Mac with
plan9port, InferNode's `mk` must come before plan9port's on the path.

`ROOT` is the InferNode the package is to run in. For an installed
Xenith.app, that is its runtime tree, with `mk` and `limbo` from a built
InferNode source tree:

```sh
export ROOT=/Applications/Xenith.app/Contents/Resources
export PATH=/path/to/infernode/MacOSX/arm64/bin:$PATH
mk install
```

After InferNode changes a module the package uses, build again from
clean: `mk nuke` and `mk install`.

Inside InferNode, bind it in:

```
run /n/local/path/to/troffpkg/troffns
```

`troffns` binds each of the package's directories after InferNode's
own (`bind -a`): the commands to `/dis`, the macros and device
descriptions to `/lib/tmac` and `/lib/troff`, the fonts to
`/fonts/libertinus`, the manual to `/man`. Nothing of InferNode's is
hidden. Run it with `run`, so that the binds are made in the calling
shell's name space. In a running Xenith, `Local run
/n/local/path/to/troffpkg/troffns` makes them in Xenith's own name
space, for every command run from it after. Put that line in your
profile to have troff in every session; delete it to remove it.

## Xenith

Xenith shows troff's output (`x T` in its first bytes) as a typeset
document, through the engine `dis/xenith/doc/trodoc.dis`. Xenith finds
engines through `/lib/xenith/doctypes`, which is InferNode's; add these
two lines to it:

    troff	binary	/dis/xenith/doc/trodoc.dis	magic=x\x20T\x20
    roff	source	/dis/xenith/doc/trodoc.dis	.ms .mm .me .man .roff .tr .t

Xenith reads `doctypes` once, when it starts, so add the lines before
starting it. The engine is loaded the first time a troff document is
opened, from Xenith's name space: `troffns` run in the shell that
starts Xenith, or later with `Local`, as above.

A document is built, then viewed: its pipeline (refer, pic, tbl, eqn,
then troff, as often as its contents and index need) makes troff's
output, and Xenith shows that. Put the build in the source window's
tag, `book book.ms`, or a pipeline, `tbl paper.ms | troff -ms
>paper.out`, and open the output, `book.out` or `paper.out`, in another
window. After each Put, middle-click the build, then Get in the
output's window.

Render, on a `.ms` or `.man` file, sets it with `troff` and the macro
package its name gives, once and with no preprocessor: for simple
documents only.

## Use

    book -p works.bib book.ms               # book.pdf, tagged (PDF/UA-1)
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
