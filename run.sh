#!/bin/bash
until nc -z localhost 8096; do
    echo "waiting for port 8096..."
    sleep 3
done

sleep 3
if [ ! -e /var/www/html/admin.json ]
then
  export CLOUDSTACK_ENDPOINT=http://127.0.0.1:8096
  export CLOUDSTACK_KEY=""
  export CLOUDSTACK_SECRET=""

  # Workaround for Nuage VPC Offering
  vpc_offering_id="$(cs listVPCOfferings listall=true name=Nuage | jq .vpcoffering[0].id)"
  cs updateVPCOffering id=$vpc_offering_id state=Disabled

  admin_id="$(cs listUsers account=admin | jq .user[0].id)"
  cs getUserKeys id=$admin_id | jq .userkeys > /var/www/html/admin.json
fi
