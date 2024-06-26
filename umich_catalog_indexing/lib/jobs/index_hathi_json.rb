require "logger"
require "securerandom"
require "fileutils"
module Jobs
  class IndexHathiJson
    def initialize(file:, solr_url:, logger: Logger.new($stdout),
      scratch_dir: "/app/scratch/#{SecureRandom.alphanumeric(8)}",
      translation_map_generator: Jobs::TranslationMapGenerator)
      @file = file
      @scratch_dir = scratch_dir
      @working_file = "#{@scratch_dir}/#{@file}"
      @logger = logger
      @solr_url = solr_url
      @translation_map_generator = translation_map_generator
    end

    def run
      @logger.info "creating scratch directory: #{@scratch_dir}"
      Dir.mkdir(@scratch_dir) unless Dir.exist?(@scratch_dir)

      @logger.info "fetching #{@file} from #{ENV.fetch("HT_HOST")}"
      fetch_hathi

      @translation_map_generator.generate_all

      @logger.info "starting traject process for #{@working_file}"
      begin
        run_traject
      rescue
        @logger.error "Traject step failed"
        @logger.info "cleaning scratch directory: #{@scratch_dir}"
        clean
        raise StandardError, "Traject step failed"
      end

      @logger.info "finished loading marc data from #{@working_file} into #{@solr_url}"
      @logger.info "cleaning scratch directory: #{@scratch_dir}"
      clean
      @logger.info "finished processing #{@file}"
    end

    def fetch_hathi
      system("curl", "-u",
        "#{ENV.fetch("HT_USERNAME")}:#{ENV.fetch("HT_PASSWORD")}",
        "#{ENV.fetch("HT_HOST")}/catalog/#{@file}", "-o",
        @working_file)
    end

    def run_traject
      success = system("bundle", "exec", "traject",
        "-c", "/app/readers/ndj.rb",
        "-c", "/app/writers/solr.rb",
        "-c", "/app/indexers/settings.rb",
        "-c", "/app/indexers/common.rb",
        "-c", "/app/indexers/common_ht.rb",
        "-c", "/app/indexers/subject_topic.rb",
        "-c", "/app/indexers/umich.rb",
        "-c", "/app/indexers/callnumbers.rb",
        "-c", "/app/indexers/umich_alma.rb",
        # "-s", "log.file=#{$stdout}",
        "-u", @solr_url,
        @working_file)
      raise StandardError unless success
    end

    def clean
      FileUtils.remove_dir(@scratch_dir)
    end

    def fetch_high_level_browse
      if should_fetch?(hlb_file)
        HighLevelBrowse.fetch_and_save(dir: hlb_dir)
        @logger.info "updated #{hlb_file}"
      else
        @logger.info "#{hlb_file} is less than one day old. Did not update"
      end
    end

    def should_fetch?(file)
      # true when file doesn't exit or if file is older than a day
      !File.exist?(file) or
        File.stat(file).mtime < Time.now - (60 * 60 * 24)
    end

    def hlb_dir
      "/app/lib/translation_maps"
    end

    def hlb_file
      "#{hlb_dir}/hlb.json.gz"
    end
  end
end
