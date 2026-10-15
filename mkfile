# mkfile for the troff package: mk ROOT=/path/to/infernode install
# builds the package against that InferNode, with its mk and limbo,
# into this package's dis/
#
# InferNode is not changed: everything goes under this directory.
<$ROOT/mkconfig

PKG=`{pwd}

DIRS=\
	appl/cmd/troff\
	appl/cmd/eqn\
	appl/cmd/tbl\
	appl/cmd/pic\
	appl/cmd/refer\
	appl/cmd/refer/style\
	appl/cmd/tr2pdf\
	appl/cmd/mkfn\
	appl/cmd\
	appl/lib\
	appl/xenith/doc\

<$ROOT/mkfiles/mksubdirs
