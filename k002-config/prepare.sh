#!/bin/bash
  
NAMESPACE=${NAMESPACE:-openstack}

RESOURCES=$(echo "secret/neutron-etc"             \
                 "secret/nova-compute-default"    \
                 "cm/neutron-bin")

mkdir config
for patch in $(ls *.patch); do
    file="${patch%.*}"
    path=config/$file
    name="${file%.*}"
    ext="${file##*.}"
    xfile="${name}\\.${ext}"
    for resource in $RESOURCES; do
        [ -e $path ] && rm $path
        [ -e $path.b64 ] && rm $path.b64
        rtype=$(dirname $resource)
        kubectl -n $NAMESPACE get $resource \
            -o "jsonpath={.data['$xfile']}" \
            > $path
        [ -z "$(cat $path)" ] && continue
        [ "$rtype" == "secret" ] && {
            mv $path $path.b64
            base64 -d $path.b64 > $path
        }
        break
    done
    echo "Patching $file ...."
    patch -d config --forward -r - < $patch
done