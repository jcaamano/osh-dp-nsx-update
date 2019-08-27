#!/bin/sh

NEUTRON_DOCKERFILE_DIR=${NEUTRON_DOCKERFILE_DIR:-.}
NEUTRON_IMAGE_TGZ=${NEUTRON_IMAGE_TGZ:-""}
NEUTRON_IMAGE="loci-neutron-nsxt:rocky-opensuse_15"
if [ -z "$NEUTRON_IMAGE_TGZ" ]; then
   echo "Building neutron container image..."
   mkdir image
   NEUTRON_IMAGE_TGZ="image/loci-neutron-nsxt-rocky-leap15.tgz"
   docker build -t $NEUTRON_IMAGE "$NEUTRON_DOCKERFILE_DIR"
   docker save $NEUTRON_IMAGE | gzip > "$NEUTRON_IMAGE_TGZ"
fi

CONTROLLER_IPS=$(kubectl get nodes --selector openstack-control-plane=enabled \
    -o jsonpath={.items[*].status.addresses[?\(@.type==\"InternalIP\"\)].address})
    
echo "Uploading image to controller nodes..."
for ip in $CONTROLLER_IPS; do
    scp "$NEUTRON_IMAGE_TGZ" ${ip}:/tmp/
    filename=$(basename "$NEUTRON_IMAGE_TGZ")
    LOADED_IMAGE_NAME=$(ssh ${ip} "docker load < /tmp/\"$filename\"" | awk '{print $NF}')
    if [ "$LOADED_IMAGE_NAME" != "$NEUTRON_IMAGE" ]; then
       ssh ${ip} "docker tag $LOADED_IMAGE_NAME $NEUTRON_IMAGE"
    fi
done