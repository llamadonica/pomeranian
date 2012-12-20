## Process this file with automake to produce Makefile.in

## Created by Anjuta

if DEBUG
DEBUG_FLAG = -DDEBUG=1
MINGW_DEBUG =
else
DEBUG_FLAG = -DDEBUG=0
MINGW_DEBUG = -mwindows
endif

if MINGW_BUILD
MINGW_FLAG = -D MINGW_BUILD
PATH_DELIMITER = "\\\\"
TRUE_PKGDATADIR = pomeranian
MINGW_CFLAG = $(MINGW_DEBUG)
else
MINGW_FLAG = 
PATH_DELIMITER = /
TRUE_PKGDATADIR = "$(pkgdatadir)"
MINGW_CFLAG =
endif



AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPKGDATADIR=\""$(TRUE_PKGDATADIR)"\" \
	-DSOUNDSDIR=\""$(TRUE_PKGDATADIR)$(PATH_DELIMITER)sounds"\" \
	-DUIDIR=\""$(TRUE_PKGDATADIR)$(PATH_DELIMITER)ui"\" \
	-DANIDIR=\""$(TRUE_PKGDATADIR)$(PATH_DELIMITER)ani"\" \
	$(DEBUG_FLAG) \
	$(POMERANIAN_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -O2

bin_PROGRAMS = pomeranian

pomeranian_SOURCES = \
	pomeranian.vala config.vapi input_rectangles.vala

pomeranian_VALAFLAGS =  \
	--pkg gio-2.0 --pkg gtk+-3.0 --pkg gee-0.8 --pkg gstreamer-0.10 --pkg cairo -g --save-temps $(MINGW_FLAG)

pomeranian_LDFLAGS = \
	-Wl,--export-dynamic $(MINGW_CFLAG)

pomeranian_LDADD = $(POMERANIAN_LIBS)

EXTRA_DIST = $(ui_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(pkgdatadir)
clean-local:
	-rm -f *.c
