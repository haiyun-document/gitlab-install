#!/bin/sh 

### BEGIN INIT INFO
# Provides: gitlab
# Required-Start: $local_fs $remote_fs $network $syslog
# Required-Stop: $local_fs $remote_fs $network $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: starts the gitlab server
# Description: starts gitlab using start-stop-daemon
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON="/usr/local/bin/bundle"
DAEMON2="/home/gitlab/gitlab/resque.sh"
NAME=unicorn
DESC="Gitlab service"

test -x $DAEMON || exit 0
test -x $DAEMON2 || exit 0

set -e

. /lib/lsb/init-functions
DAEMON_OPTS="exec unicorn_rails -c /home/gitlab/gitlab/config/unicorn.rb -E production -D"
PID=/home/gitlab/gitlab/tmp/pids/unicorn.pid
PID2="/home/gitlab/gitlab/tmp/pids/resque_worker.pid"
dir='/home/gitlab/gitlab'
case "$1" in
	start)
		echo -n "Starting $DESC: "
		start-stop-daemon --start --chuid gitlab --quiet --pidfile $PID \
			--exec $DAEMON --chdir $dir -- $DAEMON_OPTS || true
		start-stop-daemon --start --chuid gitlab --quiet --pidfile $PID2 \
			--exec $DAEMON2 --chdir $dir  || true
		echo "$NAME."
		;;

	stop)
		echo -n "Stopping $DESC: "
		start-stop-daemon --stop --quiet --pidfile $PID \
			--name ruby --chdir $dir || true
		start-stop-daemon --stop --chuid gitlab --quiet --pidfile $PID2 \
			--name ruby --chdir $dir || true
		echo "$NAME."
		;;

	restart|force-reload)
		echo -n "Restarting $DESC: "
		start-stop-daemon --stop --quiet --pidfile \
			$PID --name ruby --chdir $dir || true
		start-stop-daemon --stop --chuid gitlab --quiet --pidfile $PID2 \
			--name ruby --chdir $dir || true
		sleep 1
		start-stop-daemon --start --chuid gitlab --quiet --pidfile \
			$PID --exec $DAEMON --chdir $dir -- $DAEMON_OPTS || true
		start-stop-daemon --start --chuid gitlab --quiet --pidfile $PID2 \
			--exec $DAEMON2 --chdir $dir  || true
		echo "$NAME."
		;;
	status)
		status_of_proc -p $PID "$DAEMON" unicorn && exit 0 || exit $?
		;;
	*)
		echo "Usage: $NAME {start|stop|restart|reload|force-reload|status}" >&2
		exit 1
		;;
esac

exit 0
