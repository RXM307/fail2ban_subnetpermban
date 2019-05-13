#!/bin/bash
echo "begin
prefix
noheader
noasname" > list.txt
echo "" > routeban.txt
grep Ban /var/log/messages* | cut -d ' ' -f 9 | sort >> ipban.txt
grep Ban /var/log/messages* | cut -d ' ' -f 10 | sort >> ipban.txt
grep Ban /var/log/messages* | cut -d ' ' -f 13 | sort >> ipban.txt
sed -i '/^$/d' ipban.txt
#cat ipban.txt | grep -v -e '^$' > ipban2.txt
cat ipban.txt | grep -v 'Ban' > ipban2.txt
cat ipban2.txt | grep -v 'banned' > ipban.txt
cat ipban.txt | grep -v '%b' > ipban2.txt
cat ipban2.txt | grep -v '"Subject:' > ipban.txt
uniq -d ipban.txt > ipban2.txt
cat ipban2.txt >> list.txt
echo "end" >> list.txt
ncat whois.cymru.com 43 < list.txt | cut -d'|' -f3 | tr -d " " | grep -v "Bulkmode" | sort -n > routeban.txt

echo "Duplicates"
cat routeban.txt > duplicates.txt

cp -fp /etc/sysconfig/iptables /etc/sysconfig/iptables.new
while read repeat
do
  DUPCHK=`grep -c "${repeat}" /etc/sysconfig/iptables.new`
  #echo ${DUPCHK}
  if [ "${DUPCHK}" == "0" ] ; then 
      awk -v ip=$repeat '/# -A INPUT -s  -j DROP/{print "-A INPUT -s "ip" -j DROP"}1' /etc/sysconfig/iptables.new > /etc/sysconfig/iptables.tmp && mv /etc/sysconfig/iptables.tmp /etc/sysconfig/iptables.new
      echo "${repeat} - Route banned"
  else
    echo "${repeat} - Route already banned"
  fi
done < duplicates.txt
datetime=`date +"%m-%d-%Y-%H-%M"`
if ! cmp /etc/sysconfig/iptables /etc/sysconfig/iptables.new >/dev/null 2>&1
then
  mv /etc/sysconfig/iptables /etc/sysconfig/iptables.bak${datetime}
  mv /etc/sysconfig/iptables.new /etc/sysconfig/iptables
  /root/updatefirewall.sh
fi

ls -tr /etc/sysconfig/iptables.bak* | head -n -30 | xargs --no-run-if-empty rm
