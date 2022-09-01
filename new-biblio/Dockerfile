FROM solr:8.11.1

ENV SOLR_AUTH_TYPE="basic"
ENV SOLR_AUTHENTICATION_OPTS="-Dbasicauth=solr:SolrRocks"
ENV SOLR_OPTS="-Denable.packages=true"

COPY --chown=solr:solr conf /biblio
#the one I can't get rid of.
COPY --chown=solr:solr lib/lucene-umich-solr-filters-2.1-solr-8.8.2.jar  /var/solr/lib/lucene-umich-solr-filters-2.1-solr-8.8.2.jar

COPY --chown=solr:solr biblio_public.der /biblio_public.der
COPY --chown=solr:solr security.json /var/solr/data/security.json
COPY --chown=solr:solr scripts/solr-security.sh /usr/bin/solr-security.sh
ENTRYPOINT ["/usr/bin/solr-security.sh"]
#COPY --chown=solr:solr ./examples /examples
