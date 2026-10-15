#!/bin/sh
# build.sh /path/to/infernode: build the package against that InferNode,
# with its native tools (mk, limbo), into this package's dis/
#
# InferNode is not changed: everything goes under this directory.
[ $# = 1 ] && [ -f "$1/mkconfig" ] || { echo "usage: $0 /path/to/infernode" >&2; exit 1; }
ROOT=$(cd "$1" && pwd)
PKG=$(cd "$(dirname "$0")" && pwd)
case $(uname -s) in Darwin) SYSHOST=MacOSX;; *) SYSHOST=$(uname -s);; esac
case ${OBJTYPE:-$(uname -m)} in x86_64|amd64) OBJTYPE=amd64;; aarch64|arm64) OBJTYPE=arm64;; *) OBJTYPE=$(uname -m);; esac
PATH="$ROOT/$SYSHOST/$OBJTYPE/bin:$PATH"
export ROOT PKG PATH
command -v mk >/dev/null && command -v limbo >/dev/null ||
	{ echo "build.sh: no mk or limbo in $ROOT/$SYSHOST/$OBJTYPE/bin; build InferNode first" >&2; exit 1; }
for d in appl/cmd/troff appl/cmd/eqn appl/cmd/tbl appl/cmd/pic appl/cmd/refer \
		appl/cmd/refer/style appl/cmd/tr2pdf appl/cmd/mkfn appl/cmd \
		appl/lib appl/xenith/doc; do
	(cd "$PKG/$d" && mk install) || { echo "build.sh: $d failed" >&2; exit 1; }
done
echo "built into $PKG/dis"
