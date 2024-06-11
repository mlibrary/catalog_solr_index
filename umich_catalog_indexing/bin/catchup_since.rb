#!/usr/local/bin/ruby

require "optparse"
require "optparse/date"
require 'date'
require_relative "../lib/sidekiq_jobs"
require_relative "../lib/index_alma_for_date"
require_relative "../lib/index_zephir_for_date"


start_date = Date.new(today.year, today.month, 1) #First of the month

solr_url = ENV.fetch("REINDEX_SOLR_URL") 
alma_path = ENV.fetch("DAILY_ALMA_FILES_PATH")
zephir_path = "production/zephir_daily"

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: catchup_alma_since.rb [options] alma||zephir||both"
  opts.on("-d", "--date=DATE", Date, "Date from which to catchup from. Default is the first of the current month") do |date|
    raise ArgumentError, "date must be today or earlier" if date > Date.today
    start_date = date
  end
  opts.on("-sSOLR", "--solr=SOLR", "Solr url to index into; options are: reindex|hatcher_prod|macc_prod; Default is reindex: #{solr_url}") do |x|
    case x
    when "reindex"
      solr_url = ENV.fetch("REINDEX_SOLR_URL") 
    when "hatcher_prod"
      solr_url = ENV.fetch("HATCHER_PRODUCTION_SOLR_URL") 
    when "macc_prod"
      solr_url = ENV.fetch("MACC_PRODUCTION_SOLR_URL") 
    else
      raise ArgumentError, "solr must be reindex|hatcher_prod|macc_prod"
    end
  end


  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if ARGV.empty? || !(["alma","zephir", "both" ].include?(ARGV[0]) )
  puts optparse
  exit(-1)
end

repository = ARGV[0]

if ["both","alma"].include?(repository)
  file_paths = SFTP.client.ls(alma_path)
  
  start_date.upto(DateTime.now) do |date|
    date_string = date.strftime("%Y%m%d")
    S.logger.info "========================"
    S.logger.info "Indexing Alma #{date_string}"
    S.logger.info "========================"
    IndexAlmaForDate.new(file_paths: file_paths, date: date_string, solr_url: solr_url).run
  end
end

if ["both","zephir"].include?(repository)
  file_paths = SFTP.client.ls(zephir_path)
  (start_date - 1).upto(DateTime.now -1) do |date|
    date_string = date.strftime("%Y%m%d")
    S.logger.info "========================"
    S.logger.info "Indexing Zephir #{date_string}"
    S.logger.info "========================"
    IndexZephirForDate.new(file_paths: file_paths, date: date_string, solr_url: solr_url).run
  end
end

