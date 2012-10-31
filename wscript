#!/usr/bin/env python

import os, os.path

VERSION = "0.1.0"
VERSION_MAJOR_MINOR =  ".".join(VERSION.split(".")[0:2])
APPNAME = "pomeranian"

srcdir = '.'
blddir = '_build_'

def options(conf):
    conf.load('compiler_c')
    conf.load('vala')
    conf.load('gnu_dirs')

def configure(conf):
    conf.load('compiler_c')
    conf.load('vala')
    conf.load('gnu_dirs')
    

    conf.check_cfg(package='glib-2.0', uselib_store='GLIB',
            atleast_version='2.32.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gobject-2.0', uselib_store='GOBJECT',
            atleast_version='2.14.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gtk+-3.0', uselib_store='GTK',
            atleast_version='3.4.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gee-1.0', uselib_store='GEE',
            atleast_version='0.6.0', mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='gstreamer-0.10', uselib_store='GSTREAMER',
            mandatory=True, args='--cflags --libs')
    conf.check_cfg(package='libcanberra-gtk3', uselib_store='CANBERRA',
           mandatory=True, args='--cflags --libs')
    
    conf.define('PACKAGE', APPNAME)
    conf.define('GETTEXT_PACKAGE', APPNAME)
    conf.define('PACKAGE_NAME', APPNAME)
    conf.define('PACKAGE_STRING', APPNAME + '-' + VERSION)
    conf.define('PACKAGE_VERSION', APPNAME + '-' + VERSION)

    conf.define('VERSION', VERSION)
    conf.define('VERSION_MAJOR_MINOR', VERSION_MAJOR_MINOR)
    
    conf.env.PKGDATADIR  = os.path.join(conf.env.DATADIR, APPNAME)
    conf.env.UIDIR       = os.path.join(conf.env.PKGDATADIR, 'ui')
    conf.env.PIXMAPSDIR  = os.path.join(conf.env.PKGDATADIR, 'pixmaps')
    conf.env.ICONSDIR    = os.path.join(conf.env.PKGDATADIR, 'icons')
    conf.env.SOUNDSDIR   = os.path.join(conf.env.PKGDATADIR, 'sounds')
    conf.env.ANIDIR      = os.path.join(conf.env.PKGDATADIR, 'ani')
    
    conf.define('PKGDATADIR',conf.env.PKGDATADIR)
    conf.define('SOUNDSDIR',conf.env.SOUNDSDIR)
    conf.define('UIDIR',conf.env.UIDIR)
    conf.define('ANIDIR',conf.env.ANIDIR)

    conf.write_config_header("config.h")

def build(bld):
    bld.recurse('src')
    bld.recurse('data')

