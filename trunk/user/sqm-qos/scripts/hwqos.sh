#!/bin/sh

txq_num="16"

func_stop()
{	
	iptables -t mangle -D FORWARD -o br0 -j MARK --set-mark 6
	iptables -t mangle -D FORWARD -i br0 -j MARK --set-mark 14 
	iptables -t mangle -D FORWARD -o br0 -p udp -j MARK --set-mark 3
	iptables -t mangle -D FORWARD -i br0 -p udp -j MARK --set-mark 11
	iptables -t mangle -D POSTROUTING -o br0 -m dscp --dscp 2 -p udp -j MARK --set-mark 2
	iptables -t mangle -D POSTROUTING -o br0 -m dscp --dscp 2 -p tcp -j MARK --set-mark 2
	iptables -t mangle -D FORWARD -o br0 -p tcp --sport 1:65535 -m connlimit --connlimit-above 4 --connlimit-saddr -j MARK --set-mark 1 
	iptables -t mangle -D FORWARD -i br0 -p tcp --dport 1:65535 -m connlimit --connlimit-above 4 --connlimit-daddr -j MARK --set-mark 9 
	iptables -t mangle -D FORWARD -o br0 -p udp -m length --length :256 -j MARK --set-mark 7
	iptables -t mangle -D FORWARD -i br0 -p udp -m length --length :256 -j MARK --set-mark 15
	qdma sch_rate 0 0 0
	qdma sch_rate 1 0 0
	qdma resv 0 4 4
	for i in $(seq 1 $((txq_num - 1)))
	do
		qdma rate $i 0 0 0 0
		qdma resv $i 0 0
	done
	exit 0
}

func_start()
{	iptables -t mangle -D FORWARD -o br0 -j MARK --set-mark 6
	iptables -t mangle -D FORWARD -i br0 -j MARK --set-mark 14 
	iptables -t mangle -D FORWARD -o br0 -p udp -j MARK --set-mark 3
	iptables -t mangle -D FORWARD -i br0 -p udp -j MARK --set-mark 11
	iptables -t mangle -D POSTROUTING -o br0 -m dscp --dscp 2 -p udp -j MARK --set-mark 2
	iptables -t mangle -D POSTROUTING -o br0 -m dscp --dscp 2 -p tcp -j MARK --set-mark 2
	iptables -t mangle -D FORWARD -o br0 -p tcp --sport 1:65535 -m connlimit --connlimit-above 4 --connlimit-saddr -j MARK --set-mark 1 
	iptables -t mangle -D FORWARD -i br0 -p tcp --dport 1:65535 -m connlimit --connlimit-above 4 --connlimit-daddr -j MARK --set-mark 9 
	iptables -t mangle -D FORWARD -o br0 -p udp -m length --length :256 -j MARK --set-mark 7
	iptables -t mangle -D FORWARD -i br0 -p udp -m length --length :256 -j MARK --set-mark 15
	
	local dlmin dlmax ulmin ulmax 
	qdma sch_rate 0 0 0
	qdma sch_rate 1 0 0
	qdma resv 0 4 4
	for i in $(seq 1 $((txq_num - 1)))
	do
		qdma rate $i 0 0 0 0
		qdma resv $i 0 0
	done
	
	for i in $(seq 1 $((txq_num - 1)))
	do
		qdma resv $i 4 4
		if [ "${i}" -le $(((txq_num / 2) - 1)) ] ; then
			qdma sch $i 1
		else
			qdma sch $i 0
		fi
	done
	

	dlmin=$(($1 * $3))
	dlmin=$((dlmin / 100))
	dlmax=$(($1 * 1))
	ulmin=$(($2 * $3))
	ulmin=$((ulmin / 100))
	ulmax=$(($2 * 1))
	for i in $(seq 1 $((txq_num - 1)))
	do
		if [ "${i}" -le $(((txq_num / 2) - 1)) ] ; then
			qdma rate $i 1 "$dlmin" 1 "$dlmax"
		else
			qdma rate $i 1 "$ulmin" 1 "$ulmax"
		fi
	done
	qdma sch_rate 0 1 "$ulmax"
	qdma sch_rate 1 1 "$dlmax"
	
	iptables -t mangle -A FORWARD -o br0 -j MARK --set-mark 6
	iptables -t mangle -A FORWARD -i br0 -j MARK --set-mark 14 
	iptables -t mangle -A FORWARD -o br0 -p udp -j MARK --set-mark 3
	iptables -t mangle -A FORWARD -i br0 -p udp -j MARK --set-mark 11
	iptables -t mangle -A POSTROUTING -o br0 -m dscp --dscp 2 -p udp -j MARK --set-mark 2
	iptables -t mangle -A POSTROUTING -o br0 -m dscp --dscp 2 -p tcp -j MARK --set-mark 2
	iptables -t mangle -A FORWARD -o br0 -p tcp --sport 1:65535 -m connlimit --connlimit-above 4 --connlimit-saddr -j MARK --set-mark 1 
	iptables -t mangle -A FORWARD -i br0 -p tcp --dport 1:65535 -m connlimit --connlimit-above 4 --connlimit-daddr -j MARK --set-mark 9
	iptables -t mangle -A FORWARD -o br0 -p udp -m length --length :256 -j MARK --set-mark 7
	iptables -t mangle -A FORWARD -i br0 -p udp -m length --length :256 -j MARK --set-mark 15
	exit 0	
}


case "$1" in
start)
	func_start $2 $3 $4
	;;
stop)
	func_stop
	;;
*)
	echo "Usage: $0 {start dl ul percentage(0.7) |stop}"
	exit 1
	;;
esac

exit 0
