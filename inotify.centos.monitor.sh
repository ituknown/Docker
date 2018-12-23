#!/bin/sh

# Inotify-tools Note:
#
# inotify-tools is a C library and a set of command-line programs for 
# Linux providing a simple interface to inotify. These programs can be 
# used to monitor and act upon filesystem events. A more detailed 
# description of the programs is further down the page. The programs 
# are written in C and have no dependencies other than a Linux kernel 
# supporting inotify.
#
# you can see and get more information it on github:
#    https://github.com/rvoicilas/inotify-tools/wiki
#
#
# Get And Download On CentOS/RHEL7
#
# `inotify-tools` is available through the EPEL repository. Install EPEL :
#
# `yum install -y epel-release && yum update`
#
# Then install package:
#
# `yum install inotify-tools`
#
# But, if In case of CentOS-7, you can just use following command:
#
# `yum --enablerepo=epel install inotify-tools`
# 
# console version:
# v3.14-8.el7.×86_64 as of 4-18-2018


# work dir path parameter
DIR=$1

# if work dir path is null, get and set
if [ !-n $DIR];then
	DIR=$(dirname $(readlink -f $0))
fi

echo -e "\n"
echo "work parh is: $DIR"

inotifyTools=$(rpm -qa | grep inotify-tools)

echo -e "\n"
echo "inotofy-tools: $inotifyTools"

echo -e "\n"
if [ -n $inotifyTools ];then
    echo "The Current System Has No 'inotify-tools' Programs, Ready to download and Install ..."
    sudo yum install -y epel-release && yum update
    sudo yum install -y inotify-tools
else
    echo "The Current System Already Has 'inotify-tools', Ready to update ..."
    sudo yum update
fi

# Inotifywait Note:
# 
# inotify-tools package have a `inotifywait` command. This command takes
# multiple arguments,the default `inotifywait` prints out and exit after
# receiving the specified event(file change). `inotifywait` can be momitored
# use the `-m` parameter. The `-e` parameter specifies the type of event to 
# listen for. If omitted, all events are listened for.
#
# Here are some commom event types:
# - `CREATE`
# - `MODIFY`
# - `COLSE_WAITE`、`CLOSE` write to successful
#
# If you want to see more, execute following command:
#   `inotifywait --help`


# kill process
pids=$(ps -aux | grep inotifywait  |grep -vE 'tail|grep' | awk '{print $2}')
for pid in $pids
do
  echo -e "\n"
  echo "find pid: $pid , kill it ..."
  kill -9 $pid
done

# Dir Create
echo -e "\n"
logDir="/var/tmp/log"
if [ ! -d $logDir ];then
    mkdir $logDir
fi

echo "log dir is: $logDir"

# Touch Log file
touch "/var/tmp/log/inotifywait.log"

# monitor
inotifywait -m -d -e "create,close_write" -o "/var/tmp/log/inotifywait.log" --format "%w%f" --timefmt '%d/%m/%y %H:%M' $DIR | while read FILE
do
  cat ${FILE}
done

echo "command execute Complete! you can execute 'tail -[number]f /var/tmp/log/inotifywait.log' to print it"
echo -e "\n"
