ARG FROM=docker.io/openstackhelm/neutron:rocky-opensuse_15
FROM ${FROM}
LABEL maintainers=jcaamano@suse.com

RUN set -ex ;\
    pip install --no-cache-dir --upgrade pyasn1 ;\
    pip install --no-cache-dir \
                "pyasn1" "neutron-lbaas<14.0.0" "neutron-fwaas<14.0.0" \
                "neutron-vpnaas<14.0.0" "networking-l2gw<14.0.0" \
                "neutron-dynamic-routing<14.0.0" "networking-sfc<8.0.0" \
                "vmware-nsxlib<14.0.0" "vmware-nsx<14.0.0"