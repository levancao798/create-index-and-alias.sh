#!/bin/bash

container=`docker ps -a | grep 'Exited' | grep 'days' | awk '{print $1}'`

for i in $container; do sleep 30s
    docker start $i
done

#echo $container
root@Node1:~/caolv/scripts# cat create-index-and-alias.sh
#!/bin/bash



function createindexandalias()
{
        echo "=== `date`, ++ reindexing $1; with timeout curl --max-time 900000 "
        rm -f /tmp/lastcurlstatus
        curl --connect-timeout 300000 --max-time 900000 -XPUT $ES:9200/$index| tee -a /tmp/lastcurlstatus
        status=$?
        if [ ` grep -c 'acknowledged":true' /tmp/lastcurlstatus ` -gt 0 ]; then
        	status=0
        fi

        echo -e 'creating aliases: {"actions":[{"add":{"index":"'$index'","alias":"'$alias1'"}}]}\n{"actions":[{"add":{"index":"'$index'","alias":"'$alias2'"}}]}'
        if [ $status -eq 0 ]; then
                curl --connect-timeout 300000  --max-time 900000 "http://$ES:9200/_aliases" --data '{"actions":[{"add":{"index":"'$index'","alias":"'$alias1'"}}]}' --compressed | tee /tmp/lastcurlstatus
                curl --connect-timeout 300000  --max-time 900000 "http://$ES:9200/_aliases" --data '{"actions":[{"add":{"index":"'$index'","alias":"'$alias2'"}}]}' --compressed | tee /tmp/lastcurlstatus
        fi
}






ES=${1:-"localhost"}

curl --connect-timeout 30000 --max-time 900000 $ES:9200/_cat/nodes | grep '*' | tee /tmp/abc ;
ES=`awk '{print $1}' /tmp/abc`
echo "ES:$ES"

for numberofdaycoming in `seq 0 31 `; do

	today_ts=`date +%s`
	daytocreateindex_ts=$((today_ts+numberofdaycoming*86400))
	daytocreateindex=`date +%y%m%d -d @${daytocreateindex_ts}`

	index_prefix=${2:-"hot_clicks_"}
	index_alias=${3:-"clicks"}
	index=${index_prefix}${daytocreateindex};
	alias1=${index_alias}_${daytocreateindex};
	alias2=${index_alias};


	createindexandalias

done
