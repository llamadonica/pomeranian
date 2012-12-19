## Process this file with automake to produce Makefile.in

dll_DATA = \
	zlib1.dll\
	libgio-2.0-0.dll\
	libfontconfig-1.dll\
	libffi-5.dll\
	libpixman-1-0.dll\
	libjpeg-8.dll\
	libgtk-3-0.dll\
	libgobject-2.0-0.dll\
	libtiff-5.dll\
	libpng15-15.dll\
	libgstreamer-0.10-0.dll\
	libintl-8.dll\
	libpangowin32-1.0-0.dll\
	libpangoft2-1.0-0.dll\
	libglib-2.0-0.dll\
	liblzma-5.dll\
	libgdk_pixbuf-2.0-0.dll\
	libgee-0.8-2.dll\
	libfreetype-6.dll\
	libgthread-2.0-0.dll\
	libpangocairo-1.0-0.dll\
	libatk-1.0-0.dll\
	libcairo-2.dll\
	libxml2-2.dll\
	libgdk-3-0.dll\
	libjasper-1.dll\
	libgmodule-2.0-0.dll\
	libcairo-gobject-2.dll\
	libpango-1.0-0.dll

dlldir = $(bindir)

EXTRA_DIST = $(dll_DATA)

clean-local:
	-rm -r *.dll
$(dll_DATA) : %.dll : ${bindir}/%.dll
	cp $< $@
	

	
