#!/bin/bash

# Node properties
# "__uuidgen__" is a placeholder to be replaced when container starts. 
# Using "node.id=(uuidgen)"" here would cause duplicate node ID problem in multi-node setup
cat > $PRESTO_DIR/etc/node.properties <<EOF
node.environment=production
node.id=__uuidgen__
node.data-dir=$PRESTO_DATA_DIR
plugin.config-dir=/opt/presto/etc/catalog
plugin.dir=/opt/presto/plugin
node.server-log-file=/var/log/presto/server.log
node.launcher-log-file=/var/log/presto/launcher.log
EOF

# JVM config
cat > $PRESTO_DIR/etc/jvm.config <<EOF
-server
-Xmx16G
-XX:+UseG1GC
-XX:-UseBiasedLocking
-XX:G1HeapRegionSize=32M
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
-XX:ReservedCodeCacheSize=512M
EOF

# Log properties
cat > $PRESTO_DIR/etc/log.properties <<EOF
com.facebook.presto=INFO
EOF

cat > $PRESTO_DIR/etc/catalog/tpch.properties <<EOF
connector.name=tpch
EOF
