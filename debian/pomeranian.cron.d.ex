#
# Regular cron jobs for the pomeranian package
#
0 4	* * *	root	[ -x /usr/bin/pomeranian_maintenance ] && /usr/bin/pomeranian_maintenance
