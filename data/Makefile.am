## Process this file with automake to produce Makefile.in

if MINGW_BUILD
icondir = $(pkgdatadir)
desktop_DATA = 
schema_DATA = gschemas.compiled
schemadir = $(datadir)/glib-2.0/schemas
else
icondir = $(datadir)/pixmaps
desktop_DATA = pomeranian.desktop
schema_DATA =
schemadir =
endif

icon_DATA = pomeranian.png

desktopdir = $(datadir)/applications

EXTRA_DIST = $(icon_DATA) $(desktop_DATA) $(schema_DATA)

SUBDIRS = ui sounds ani

uninstall-local:
	-rm -r $(pkgdatadir)
	-rm -r $(schemadir)
SCHEMAS:
	mkdir schemas
	cp /usr/share/glib-2.0/schemas/*.xml schemas/
	touch SCHEMAS
gschemas.compiled: | SCHEMAS
	glib-compile-schemas /usr/share/glib-2.0/schemas --targetdir=.
	
	
