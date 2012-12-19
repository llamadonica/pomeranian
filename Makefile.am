## Process this file with automake to produce Makefile.in
## Created by Anjuta

if MINGW_BUILD
DLLDIR = dll
else
DLLDIR =
endif

SUBDIRS = src \
	data \
	po \
	$(DLLDIR)

pomeraniandocdir = ${prefix}/doc/pomeranian
pomeraniandoc_DATA = \
	README\
	COPYING\
	AUTHORS\
	ChangeLog\
	INSTALL\
	NEWS


EXTRA_DIST = config.rpath m4/ChangeLog  $(pomeraniandoc_DATA)

# Remove doc directory on uninstall
uninstall-local:
	-rm -r $(pomeraniandocdir)

ACLOCAL_AMFLAGS = -I m4
