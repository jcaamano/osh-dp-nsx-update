#!/bin/bash

RESOURCES=$(echo "deploy/neutron-server"             \
                 "ds/nova-compute-default"           \
                 "job/neutron-db-init"               \
                 "job/neutron-db-sync")

NAMESPACE=${NAMESPACE:-openstack}

mkdir resources
pushd resources
    for resource in $RESOURCES; do
        echo "Fetching resource $resource...."
        rtype=$(dirname $resource)
        rname=$(basename $resource)
        kubectl -n $NAMESPACE get $resource --export -o yaml > $rtype-$rname.yaml
    done
popd
