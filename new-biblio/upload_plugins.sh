docker-compose exec solr bin/solr package add-key /biblio_public.der

declare -A jars_to_package=( 
#["CJKFilterUtils-v3.0-1.8.jar"]="cjk_filter_utils" 
#["CJKFilterUtils-v3.0-SNAPSHOT.jar"]="cjk_filter_utils_snap"
#["icu4j-62.1.jar"]="icu4j" 
#["lucene-analyzers-icu-8.2.0.jar"]="lucene_analyzers_icu" 
#["lucene-analyzers-icu-8.11.1.jar"]="lucene_analyzers_icu" 



#["solr_analyzed_string-1.0.jar"]="solr_analyzed_string" 
["library_identifier_solr_filters-0.9.5-solr8.8.2.jar"]="library_identifier_solr_filters" 
#["lucene-umich-solr-filters-2.1-solr-8.8.2.jar"]="lucene_umich_solr_filters" 
)



declare -A jars_to_version=( ["CJKFilterUtils-v3.0-1.8.jar"]="3.0.1.8" ["CJKFilterUtils-v3.0-SNAPSHOT.jar"]="3.0"
["icu4j-62.1.jar"]="62.1" 
["library_identifier_solr_filters-0.9.5-solr8.8.2.jar"]="0.9.5" 
["lucene-analyzers-icu-8.2.0.jar"]="8.2.0" 
["lucene-analyzers-icu-8.11.1.jar"]="8.11.1" 
["lucene-umich-solr-filters-2.1-solr-8.8.2.jar"]="2.1" 
["solr_analyzed_string-1.0.jar"]="1.0" )

for jar in "${!jars_to_package[@]}"; 
do 
  signature=$(openssl dgst -sha1 -sign biblio.pem lib/$jar | openssl enc  -base64 | sed 's/+/%2B/g' | tr -d \\n  );
  echo $signature
  curl -u solr:SolrRocks --data-binary @lib/$jar -X PUT  http://localhost:8983/api/cluster/files/${jars_to_package[$jar]}/${jars_to_version[$jar]}/$jar?sig=$signature
done

for jar in "${!jars_to_package[@]}"; 
do 
  curl -u solr:SolrRocks http://localhost:8983/api/cluster/package -H 'Content-type:application/json' -d  "
    {'add': {
             'package' :'${jars_to_package[$jar]}',
             'version':'${jars_to_version[$jar]}',
             'files' :['/${jars_to_package[$jar]}/${jars_to_version[$jar]}/$jar']
           }
    }"
done

