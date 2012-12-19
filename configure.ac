dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.


AC_INIT(pomeranian, 0.3.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11])

AM_SILENT_RULES([yes])

AC_PROG_CC
AM_PROG_CC_C_O

AS_CASE([$host],
       [*-*-mingw32], [mingw=true],
       [mingw=false]
     )



AC_ARG_ENABLE([debug],
	[  --enable-debug    Turn on debugging],
	[case "${enableval}" in
		yes) debug=true ;;
		no)  debug=false ;;
		*) AC_MSG_ERROR([bad value ${enableval} for --enable-debug]) ;;
		esac],[debug=false])

AM_CONDITIONAL([DEBUG], [test x$debug = xtrue])
AM_CONDITIONAL([MINGW_BUILD], [test x$mingw = xtrue])

PACKAGE=pomeranian

dnl Check for vala
AM_PROG_VALAC([0.16.0])


PKG_CHECK_MODULES(POMERANIAN, glib-2.0
gobject-2.0
gstreamer-0.10
gee-0.8
gtk+-3.0)


ALL_LINGUAS=""
AM_GLIB_GNU_GETTEXT

GETTEXT_PACKAGE=pomeranian
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["${GETTEXT_PACKAGE}"], [gettext domain])

AS_CASE([$host],
       [*-*-mingw32], [AC_CONFIG_FILES([ dll/Makefile
		 ])]
     )

AC_CONFIG_FILES([ po/Makefile.in
Makefile
src/Makefile
data/pomeranian.desktop
data/Makefile
data/ani/Makefile
data/ui/Makefile
data/sounds/Makefile
])

AC_OUTPUT

