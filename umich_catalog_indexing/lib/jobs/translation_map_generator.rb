module Jobs
  module TranslationMapGenerator
    class << self
      def all
        [
          HighLevelBrowse,
          LibLocInfo,
          SubjectHeadingRemediation
        ]
      end

      def translation_map_directory
        S.translation_map_dir
      end

      def generate_all(dir: translation_map_directory)
        all.each do |klass|
          generate(generator: klass, dir: dir)
        end
      end

      def generate(generator:, dir: translation_map_directory, force: false)
        S.logger.info "fetching #{generator.name}"
        path = File.join(dir, generator.file_path)
        if _should_not_fetch?(path) && force == false
          S.logger.info "#{path} is less than one day old. Did not update"
          return
        end
        temporary_path = "#{path}_#{SecureRandom.alphanumeric(8)}.temporary"
        generator.write_to_file(temporary_path)
        raise StandardError, "#{temporary_path} does not exist; Failed to load file" if !File.exist?(temporary_path)
        raise StandardError, "#{temporary_path} is too small; Failed to load file" if File.size?(temporary_path) < 15
        File.rename(temporary_path, path)
        S.logger.info "updated #{path}"
      end

      def _should_not_fetch?(file)
        !_should_fetch?(file)
      end

      def _should_fetch?(file)
        # true when file doesn't exit or if file is older than a day
        !File.exist?(file) or
          File.stat(file).mtime < Time.now - (60 * 60 * 24)
      end
    end

    module FileWriter
      # Mixin for writing the translation map to given the file path. This method expects the class method .generate_translation_map
      # @param path [String] path to location to write the file
      def write_to_file(path)
        File.write(path, generate)
      end
    end
  end
end

require_relative "translation_map_generator/electronic_collections"
require_relative "translation_map_generator/lib_loc_info"
require_relative "translation_map_generator/high_level_browse"
require_relative "translation_map_generator/subject_heading_remediation"
require_relative "translation_map_generator/floor_locations"
require_relative "translation_map_generator/electronic_collections_ranking"
