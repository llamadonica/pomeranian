## Process this file with automake to produce Makefile.in

## Created by Anjuta

if DEBUG
DEBUG_FLAG = -DDEBUG=1
else
DEBUG_FLAG = -DDEBUG=0
endif

AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPKGDATADIR=\""$(pkgdatadir)"\" \
	-DSOUNDSDIR=\""$(pkgdatadir)/sounds"\" \
	-DUIDIR=\""$(pkgdatadir)/ui"\" \
	-DANIDIR=\""$(pkgdatadir)/ani"\" \
	$(DEBUG_FLAG) \
	$(POMERANIAN_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = pomeranian

pomeranian_SOURCES = \
	pomeranian.vala config.vapi input_rectangles.vala

pomeranian_VALAFLAGS =  \
	--pkg gio-2.0 --pkg gtk+-3.0 --pkg gee-1.0 --pkg libcanberra --pkg libcanberra-gtk --pkg gstreamer-0.10 --pkg cairo -g --save-temps --define=DEBUG

pomeranian_LDFLAGS = \
	-Wl,--export-dynamic 

pomeranian_LDADD = $(POMERANIAN_LIBS)

EXTRA_DIST = $(ui_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(pkgdatadir)
