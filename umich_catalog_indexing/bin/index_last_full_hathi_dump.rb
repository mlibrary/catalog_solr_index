#!/usr/local/bin/ruby
#require "date"
#require_relative "../lib/sidekiq_jobs"
#require "logger"

##########
## TBDeleted
## Preprocessing of zephir records happens outside of Traject. Assuming all goes
## well the following can be deleted after July 1, 2024.
##########
#logger = Logger.new($stdout)
#logger.info "Starting submission of HathiTrust monthly full job"

#hathi_file = Jobs::Utilities::ZephirFile.latest_monthly_full

#logger.info "Sending job to index #{hathi_file} into reindex solr: #{ENV.fetch("REINDEX_SOLR_URL")}"

#IndexHathi.set(queue: 'reindex').perform_async(hathi_file, ENV.fetch("REINDEX_SOLR_URL"))

#logger.info "Finished submitting HathiTrust monthly full job"
