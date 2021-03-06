#!/bin/sh

DIR=`pwd`

mkdir -p /tmp/bosh_downloads

pushd /tmp/bosh_downloads
    KIBANA_VERSION=6.8.16
    if [ ! -f ${DIR}/blobs/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz ];then
        curl -L -J -o kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz
        bosh add-blob --dir=${DIR} kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz
    fi
popd
