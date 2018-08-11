#!/bin/bash +x

/usr/bin/mysqld_safe &
cd /opt/cloudstack && mvn -pl client jetty:run -Dsimulator -Dorg.eclipse.jetty.annotations.maxWait=120 &

until nc -z localhost 8096; do
    echo "waiting for port 8096..."
    sleep 3
done

sleep 3
python /opt/cloudstack/tools/marvin/marvin/deployDataCenter.py -i /opt/zones.cfg
