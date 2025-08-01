module Traject
  module UMich
    class ElectronicHolding
      RANKING = Traject::TranslationMap.new("umich/electronic_collections_ranking")
      def initialize(e56)
        @e56 = e56
      end

      def library
        "ELEC"
      end

      def link
        code = (_alma_campuses.count == 1 && _alma_campuses.first == "UMFL") ? "UMFL" : "UMAA"
        URI::DEFAULT_PARSER.escape(@e56["u"].sub("openurl", "openurl-#{code}"))
      end

      def link_text
        "Available online"
      end

      def campuses
        inst_code_map = {
          "UMAA" => "ann_arbor",
          "UMFL" => "flint"
        }
        # return flint when it's the only campus
        if _alma_campuses.empty?
          inst_code_map.values
        else
          _alma_campuses.map { |code| inst_code_map[code] }
        end
      end

      def institution_codes
        inst_code_map = {
          "UMAA" => "MIU",
          "UMFL" => "MIFLIC"
        }
        if _alma_campuses.empty?
          inst_code_map.values
        else
          _alma_campuses.map { |code| inst_code_map[code] }
        end
      end

      def interface_name
        @e56["m"]
      end

      def collection_name
        @e56["n"] || ""
      end

      def collection_id
        @e56["k"]
      end

      def ranking
        (RANKING[collection_id]&.dig("ranking") || 99_999).to_i
      end

      def authentication_note
        @e56.subfields.filter_map { |x| x.value if x.code == "4" }
      end

      def public_note
        @e56["z"]
      end

      # Concatentates interface name, collection name, authentication note, and
      # public note. Also strips out any trailing punctuation except closing
      # parens and square brackets. The rest are terminated with a period.
      def note
        [
          interface_name,
          collection_name,
          authentication_note,
          public_note
        ].flatten.reject { |x| x.to_s.empty? }.map do |x|
          out = x.strip
            .sub(/[[\p{P}]&&[^\])]]$/, "")
          out.sub!(/$/, ".") if out.match?(/[^\])]$/)
          out
        end.join(" ")
      end

      def status
        @e56["s"]
      end

      def description
        @e56["3"]
      end

      def finding_aid
        false
      end

      def to_h
        [
          "library",
          "link",
          "link_text",
          "campuses",
          "interface_name",
          "collection_name",
          "authentication_note",
          "description",
          "public_note",
          "note",
          "finding_aid",
          "status"
        ].map do |x|
          [x, public_send(x)]
        end.to_h
      end

      def _alma_campuses
        @e56.subfields.filter_map { |x| x.value if x.code == "c" }
      end
    end
  end
end
