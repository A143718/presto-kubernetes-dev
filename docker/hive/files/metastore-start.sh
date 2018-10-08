#!/bin/bash

export HIVE_DIR=/usr/local/hive

# Update config file with credentials for WASB and ADLS
config=$HIVE_DIR/conf/hive-site.xml

AZURE_STORAGE_ACCOUNT_NAME=$(echo ${AZURE_STORAGE_ACCOUNT_NAME} | tr -d '\n')
AZURE_STORAGE_ACCOUNT_KEY=$(echo ${AZURE_STORAGE_ACCOUNT_KEY} | tr -d '\n')
#MYSQL_HOST=$(echo ${MYSQL_HOST} | tr -d '\n')
#MYSQL_USERNAME=$(echo ${MYSQL_USERNAME} | tr -d '\n')
MYSQL_PASSWORD=$(echo ${MYSQL_PASSWORD} | tr -d '\n')


sed -i -e "s/AZURE_STORAGE_ACCOUNT_NAME/${AZURE_STORAGE_ACCOUNT_NAME}/g" $config
sed -i -e "s|AZURE_STORAGE_ACCOUNT_KEY|${AZURE_STORAGE_ACCOUNT_KEY}|g" $config
sed -i -e "s|MYSQL_HOST|${MYSQL_HOST}|g" $config
sed -i -e "s|MYSQL_USERNAME|${MYSQL_USERNAME}|g" $config
sed -i -e "s|MYSQL_PASSWORD|${MYSQL_PASSWORD}|g" $config

# Start Hadoop
/etc/bootstrap.sh

# Start the metastore
hive --service metastore --hiveconf hive.root.logger=DEBUG,console --hiveconf fs.azure.account.key.${AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net=''${AZURE_STORAGE_ACCOUNT_KEY}'' --hiveconf fs.adl.impl=org.apache.hadoop.fs.adl.AdlFileSystem --hiveconf fs.AbstractFileSystem.adl.impl=org.apache.hadoop.fs.adl.Adl --hiveconf dfs.adls.oauth2.access.token.provider.type=ClientCredential --hiveconf dfs.adls.oauth2.client.id=${ADLS_CLIENT_ID} --hiveconf dfs.adls.oauth2.credential=${ADLS_CLIENT_SECRET} --hiveconf dfs.adls.oauth2.refresh.url=https://login.microsoftonline.com/${ADLS_TENANT_ID}/oauth2/token --hiveconf datanucleus.schema.autoCreateAll=true --hiveconf hive.metastore.schema.verification=false --hiveconf hive.exec.scratchdir=/tmp/hive --hiveconf hive.exec.local.scratchdir=/tmp/hivelocal

# Spin wait
while true; do sleep 1000; done
