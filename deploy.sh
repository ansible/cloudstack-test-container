#!/bin/bash +x
set -euo pipefail
export PATH="/root/.local/bin:$PATH"

# Run the CloudStack Simulator
/usr/bin/supervisord --silent &

echo "--- Waiting for CloudStack Simulator to start ---"
sleep 30
until nc -z localhost 8096; do
    echo "--- ...waiting for port 8096... ---"
    sleep 3
done
sleep 10
echo "--- Deploying CloudStack Simulator Zones (this will take some minutes...) ---"
python3 /root/tools/marvin/marvin/deployDataCenter.py -i /opt/zones.cfg

export CLOUDSTACK_ENDPOINT=http://127.0.0.1:8096
export CLOUDSTACK_KEY=dummy
export CLOUDSTACK_SECRET=dummy

# Add Simulator to supported hypervisors exclusively
cs updateConfiguration name=hypervisor.list value=Simulator

# Stop the CloudStack Simulator
supervisorctl stop all

echo "--- CloudStack Simulator Zones deployed ---"
