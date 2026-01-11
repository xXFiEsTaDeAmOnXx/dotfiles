#!/bin/bash
REGISTRY="fbe-dockerreg.rwu.de"


echo "Using $REGISTRY"

images=$(docker image list --format "{{.Repository}}:{{.Tag}}" | grep $REGISTRY)


for image in $images; do
    echo "Updating $image ..."
    docker pull $image
done

echo "Done updating all images"

