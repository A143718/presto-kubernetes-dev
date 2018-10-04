#!/bin/bash

export PRESTO_DIR=/opt/presto

# Update config file with credentials for WASB and ADLS
config=$PRESTO_DIR/etc/catalog/adls-wasb-site.xml

sed -i -e "s/ADLS_TENANT_ID/${ADLS_TENANT_ID}/g" $config
sed -i -e "s/ADLS_CLIENT_ID/${ADLS_CLIENT_ID}/g" $config
sed -i -e "s#ADLS_CLIENT_SECRET#${ADLS_CLIENT_SECRET}#g" $config

sed -i -e "s/AZURE_STORAGE_ACCOUNT_NAME/${AZURE_STORAGE_ACCOUNT_NAME}/g" $config
sed -i -e "s#AZURE_STORAGE_ACCOUNT_KEY#${AZURE_STORAGE_ACCOUNT_KEY}#g" $config

# generate unique node.id
sed -i -e "s/__uuidgen__/$(uuidgen)/g" $PRESTO_DIR/etc/node.properties

# Create additional catalogs...
coordinator_config() {
  (
    echo "coordinator=true"
    echo "node-scheduler.include-coordinator=false"
    echo "http-server.http.port=${HTTP_SERVER_PORT}"
    echo "query.max-memory=${PRESTO_MAX_MEMORY}GB"
    echo "query.max-memory-per-node=${PRESTO_MAX_MEMORY_PER_NODE}GB"
    echo "query.max-total-memory-per-node=${PRESTO_MAX_MEMORY_PER_NODE}GB"
    echo "discovery-server.enabled=true"
    echo "discovery.uri=http://localhost:${HTTP_SERVER_PORT}"
  ) >$PRESTO_DIR/etc/config.properties
}

worker_config() {
  (
    echo "coordinator=false"
    echo "http-server.http.port=${HTTP_SERVER_PORT}"
    echo "query.max-memory=${PRESTO_MAX_MEMORY}GB"
    echo "query.max-memory-per-node=${PRESTO_MAX_MEMORY_PER_NODE}GB"
    echo "query.max-total-memory-per-node=${PRESTO_MAX_MEMORY_PER_NODE}GB"
    echo "discovery.uri=http://${COORDINATOR}:${HTTP_SERVER_PORT}"
  ) >$PRESTO_DIR/etc/config.properties
}

if [ -z "${COORDINATOR}" ]; then coordinator_config; else worker_config; fi

jvm_config() {
  sed -i "s/-Xmx.*G/-Xmx${PRESTO_JVM_HEAP_SIZE}G/" $PRESTO_DIR/etc/jvm.config
}

# Update the JVM configuration for any node. Only if the PRESTO_JVM_HEAP_SIZE
# parameter is set.
[ -n "${PRESTO_JVM_HEAP_SIZE}" ] && jvm_config

cat > $PRESTO_DIR/etc/catalog/hive.properties <<EOF
connector.name=hive-hadoop2
hive.metastore.uri=thrift://${HIVE_METASTORE_HOST}:${HIVE_METASTORE_PORT}
hive.config.resources=${PRESTO_DIR}/etc/catalog/adls-wasb-site.xml
hive.storage-format=PARQUET
hive.compression-codec=SNAPPY
hive.allow-drop-table=true
hive.recursive-directories=true
hive.parquet-optimized-reader.enabled=true
hive.parquet-predicate-pushdown.enabled=true
EOF

# Azure CosmosDB with MongoAPI
if [ -n "$MONGODB_SEEDS" ]; then
cat > $PRESTO_DIR/etc/catalog/cosmosdb.properties <<EOF
connector.name=mongodb
mongodb.seeds=$MONGODB_SEEDS
mongodb.credentials=$MONGODB_CREDENTIALS
mongodb.ssl.enabled=$MONGODB_SSL_ENABLED
EOF
fi

# Azure SQL Database
if [ -n "$SQLSERVER_JDBC_URL" ]; then
cat > $PRESTO_DIR/etc/catalog/azuresql.properties <<EOF
connector.name=sqlserver
connection-url=$SQLSERVER_JDBC_URL
connection-user=$SQLSERVER_USERNAME
connection-password=$SQLSERVER_PASSWORD
EOF
fi

# MySQL 
if [ -n "$MYSQL_JDBC_URL" ]; then
cat > $PRESTO_DIR/etc/catalog/mysql.properties <<EOF
connector.name=mysql
connection-url=$MYSQL_JDBC_URL
connection-user=$MYSQL_USERNAME
connection-password=$MYSQL_PASSWORD
EOF
fi

# PostreSQL 
if [ -n "$POSTGRESQL_JDBC_URL" ]; then
cat > $PRESTO_DIR/etc/catalog/postgresql.properties <<EOF
connector.name=postgresql
connection-url=$POSTGRESQL_JDBC_URL
connection-user=$POSTGRESQL_USERNAME
connection-password=$POSTGRESQL_PASSWORD
EOF
fi


# Start Presto
/opt/presto/bin/launcher run

# Spin wait
while true; do sleep 1000; done
