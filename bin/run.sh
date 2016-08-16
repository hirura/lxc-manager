#!/bin/sh

start()
{
	pgrep -f "ruby ${_lxc_mgr_dir}/daemon.rb" >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		echo "lxc-manager is ALREADY running."
	else
		nohup ruby ${_lxc_mgr_dir}/daemon.rb >/dev/null 2>&1 </dev/null &
	fi
}

stop()
{
	pgrep -f "ruby ${_lxc_mgr_dir}/daemon.rb" >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		pkill -f "ruby ${_lxc_mgr_dir}/daemon.rb"
	else
		echo "lxc-manager is ALREADY stopped."
	fi
}

forcestop()
{
	pgrep -f "ruby ${_lxc_mgr_dir}/daemon.rb" >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		pkill -KILL -f "ruby ${_lxc_mgr_dir}/daemon.rb"
	else
		echo "lxc-manager is ALREADY stopped."
	fi
}

status()
{
	pgrep -f "ruby ${_lxc_mgr_dir}/daemon.rb" >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		echo "lxc-manager is running."
	else
		echo "lxc-manager is stopped."
	fi
}


_dir=$(cd $(dirname $0) && pwd)
_lxc_mgr_dir=$(cd ${_dir}/../lib/lxc-manager && pwd)

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	forcestop)
		forcestop
		;;
	restart)
		stop
		start
		;;
	forcerestart)
		forcestop
		start
		;;
	status)
		status
		;;
	*)
		echo $"Usage: $0 {start|stop|forcestop|restart|forcerestart|status}"
esac
