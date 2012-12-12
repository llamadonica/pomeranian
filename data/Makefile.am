## Process this file with automake to produce Makefile.in

icondir = $(datadir)/pixmaps
icon_DATA = pomeranian.png

desktopdir = $(datadir)/applications
desktop_DATA = pomeranian.desktop

EXTRA_DIST = $(icon_DATA)

SUBDIRS = ui sounds ani

uninstall-local:
	-rm -r $(pkgdatadir)
