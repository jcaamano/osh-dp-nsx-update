#!/bin/bash

# This needs
# 1. kubectl and a cluster kubeconfig
# 2. password-less access to controller nodes
# 3. both local and controller docker permissions
# 4. A correctly configured nsxt_conf.ini

# The compute nodes need to be configured as transport nodes in
# the same NSX-T controller as specified in nsx_conf.ini

GOPATH=${GOPATH:-~/go}

help_go() {
    echo "We need a go environment and kustomize and a kustomize plugin:"
    echo "1. Install go 1.12"
    echo "2. cd kustomize/plugin/osh_dp_nsx/hashtransformer"
    echo "3. go build -buildmode plugin -o HashTransformer.so HashTransformer.go"
    echo "4. go get sigs.k8s.io/kustomize/v3/cmd/kustomize"
    echo "Good luck with that!"
    exit
}

help_nsx_conf() {
    echo "Missing k004-config/nsx_conf.ini"
    echo "Prepare one from k004-config/nsx_conf.ini.sample"
    exit
}

[ ! -x "${GOPATH}/bin/kustomize" ] && help_go
[ ! -f "kustomize/plugin/osh_dp_nsx/grouphashtransformer/GroupHashTransformer.so"] && help_go
[ ! -f "k002-config/nsx_conf.ini"] && help_nsx_conf

NAMESPACE=${NAMESPACE:-openstack}
kustomize="XDG_CONFIG_HOME=${SCRIPT_PATH} ${GOPATH}/bin/kustomize"

SCRIPT_PATH=$(dirname $(realpath -s $0))
pushd $SCRIPT_PATH
    for dir in $(ls -d k*); do
        echo "Preparing $dir..."
        pushd $dir
            [ -x ./prepare.sh] && ./prepare.sh
        popd
        $kustomize edit set namespace $NAMESPACE
    done
popd

echo "Applying kustomization from top overlay $dir..."
$kustomize build --enable_alpha_plugins $dir > nsx_update.yaml

echo "Customization should be ready, proceed with:"
echo "1. Deleting neutron agent DaemonSets:"
echo "   kubectl delete -n $NAMESPACE ds --ignore-not-found=true -l application=neutron"
echo "2. Deleting openvswitch DaemonSets:"
echo "   kubectl delete -n $NAMESPACE ds --ignore-not-found=true -l application=openvswitch"
echo "3. Drop the neutron database:"
echo "   kubectl -n openstack -it exec mariadb-server-0 -- mysql -h mariadb.openstack -uroot -ppassword -e 'drop database neutron;'"
echo "4. Review the updates nsx_update.yaml and apply:"
echo "   kubectl apply -f nsx_update.yaml"
echo "5. Configure the compute nodes as transport nodes on the NSX-T controller used in nsx_conf.ini"
