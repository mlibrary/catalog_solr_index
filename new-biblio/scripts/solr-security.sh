#!/bin/bash
solr zk cp /var/solr/data/security.json zk:security.json -z zoo:2181
solr zk upconfig -z  zoo:2181 -n biblio -d /biblio
exec /opt/docker-solr/scripts/docker-entrypoint.sh "$@"
