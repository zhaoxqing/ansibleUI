#/bin/bash
#rsync auto sync script with inotify
#2014-12-11 Sean
#variables

#Modify by lisongtao  2015/11/19

current_date=$(date +%Y%m%d_%H%M%S)
source_path=/srv/log/
log_file=/var/log/rsync_client.log

#rsync
rsync_server=10.3.6.27

rsync_user=www
rsync_pwd=/etc/rsync_client.pwd
rsync_module=module_uat
INOTIFY_EXCLUDE='(.*/*\.log|.*/*\.swp)$|^/tmp/src/mail/(2014|20.*/.*che.*)'
RSYNC_EXCLUDE='/etc/rsyncd.d/rsync_exclude.lst'
IPADDR=`ifconfig  |grep -v 127.0.0.1| awk -F'[ :]+' '/inet addr/{printf "-"$4}END{print}'`
Mark="uat"


#rsync client pwd check
if [ ! -e ${rsync_pwd} ];then
    echo -e "rsync client passwod file ${rsync_pwd} does not exist!"
    exit 0
fi


#400 error
Error400 (){
echo "exit ,Plz check"
exit 400
}


#inotify_function
inotify_fun(){
    /usr/bin/inotifywait -mrq --timefmt '%Y/%m/%d-%H:%M:%S' --format '%T %w %f' \
          --exclude ${INOTIFY_EXCLUDE}  -e modify,delete,create,move,attrib ${source_path} \
          | while read file
      do
          /usr/bin/rsync -auvrtzopgP --exclude-from=${RSYNC_EXCLUDE} --progress --bwlimit=200 --password-file=${rsync_pwd}  ${source_path} ${rsync_user}@${rsync_server}::${rsync_module}/${Mark}${IPADDR}
      done
}

#inotify log
[[ `pidof inotifywait` ]] &&  Error400
inotify_fun >> ${log_file} 2>&1 &
