#!/bin/bash

# Enables job control
set -m

# Enables error propagation
set -e

# Run the server and send it to the background
    /entrypoint.sh couchbase-server &

    # Check if couchbase server is up
    check_db() {
    curl --silent http://127.0.0.1:8091/pools > /dev/null
    echo $?
    }

    # Variable used in echo
    i=1
    # Echo with
    log() {
    echo "[$i] [$(date +"%T")] $@"
    i=`expr $i + 1`
    }

    # Wait until it's ready
    until [[ $(check_db) = 0 ]]; do
    >&2 log "Waiting for Couchbase Server to be available ..."
    sleep 1
    done

    # Setup index and memory quota
    log "$(date +"%T") Init cluster ........."
    couchbase-cli cluster-init -c 127.0.0.1 --cluster-username Administrator --cluster-password password \
    --cluster-name myCluster --cluster-ramsize 512 --cluster-index-ramsize 256 --services data,index,query,fts \
    --index-storage-setting memopt

    # Create the buckets
    log "$(date +"%T") Create buckets ........."
    couchbase-cli bucket-create -c 127.0.0.1 --username Administrator --password password --bucket-type ephemeral --bucket-ramsize 250 --bucket Worlds
    couchbase-cli bucket-create -c 127.0.0.1 --username Administrator --password password --bucket-type ephemeral --enable-flush 1  --bucket-ramsize 250 --bucket WorldsTest

    # Create user
    log "$(date +"%T") Create users ........."
    couchbase-cli user-manage -c 127.0.0.1:8091 -u Administrator -p password --set --rbac-username sysadmin --rbac-password password \
    --rbac-name "sysadmin" --roles admin --auth-domain local

    couchbase-cli user-manage -c 127.0.0.1:8091 -u Administrator -p password --set --rbac-username admin --rbac-password password \
    --rbac-name "admin" --roles bucket_full_access[*] --auth-domain local

    # Need to wait until query service is ready to process N1QL queries
    log "$(date +"%T") Waiting ........."
    sleep 20

    # Create bucket1 indexes
    echo "$(date +"%T") Create Worlds indexes ........."
    cbq -u Administrator -p password -s "CREATE PRIMARY INDEX idx_primary ON \`Worlds\`;"

    # Create bucket2 indexes
    echo "$(date +"%T") Create Worlds indexes ........."
    cbq -u Administrator -p password -s "CREATE PRIMARY INDEX idx_primary ON \`WorldsTest\`;"
fg 1
