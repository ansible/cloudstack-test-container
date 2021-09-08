#!/bin/bash +x

/usr/bin/mysqld_safe &
cd /opt/cloudstack && mvn -pl client jetty:run -Dsimulator -Dorg.eclipse.jetty.annotations.maxWait=120 &

until nc -z localhost 8096; do
    echo "waiting for port 8096..."
    sleep 3
done

sleep 3
export CLOUDSTACK_ENDPOINT=http://127.0.0.1:8096
export CLOUDSTACK_KEY=dummy
export CLOUDSTACK_SECRET=dummy

# Add Simulator to supported hypervisors exclusively
cs updateConfiguration name=hypervisor.list value=Simulator
