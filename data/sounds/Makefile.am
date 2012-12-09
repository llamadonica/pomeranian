## Process this file with automake to produce Makefile.in

soundsdir = $(pkgdatadir)/sounds
sounds_DATA = ring.ogg tick-loop.ogg wind.ogg

EXTRA_DIST = $(sounds_DATA)

uninstall-local:
	-rm -r $(soundsdir)
