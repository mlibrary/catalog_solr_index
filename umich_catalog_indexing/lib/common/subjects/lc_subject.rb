# frozen_string_literal: true

require_relative "normalize"

module Common
  class Subjects
    class LCSubject
      include Common::Subjects::Normalize

      # Create an LC Subject object from the passed field
      # @param [MARC::DataField] field _that has already been determined to be LC_
      # @return [LCSubject] An LC Subject or appropriate subclass
      def self.from_field(field)
        case field.tag
        when "658"
          LCSubject658.new(field)
        when "662"
          LCSubjectHierarchical.new(field)
        when "752"
          LCAddedEntryHeirarchical.new(field)
        else
          new(field)
        end
      end

      # In theory, an LC subject field is any 6xx with ind2==0
      # Sometimes we get subject fields with ind2=0 that are NOT LC. In many of theses
      # cases, the field correctly has a $2 ("Source of heading or term"). If that $2 exists,
      # and isn't "lcsh", we designate the field as "not LCSH".
      # @param [MARC::DataField] field A 6XX field
      # @return [Boolean]
      def self.lc_subject_field?(field)
        SUBJECT_FIELDS.include?(field.tag) &&
          field.indicator2 == "0" &&
          lcsh_subject_field_2?(field)
      end

      # @param [MARC::DataField] field A 6xx field
      def self.lcsh_subject_field_2?(field)
        field["2"].nil? || field["2"] == "lsch"
      end

      def initialize(field)
        @field = field
      end

      # Get all the subfields that have data (as opposed to field-level metadata, like a $2)
      def subject_data_subfield_codes
        @field.select { |sf| ("a".."z").cover?(sf.code) }
      end

      def default_delimiter
        "--"
      end

      # Here for testing purposes to distinguish from the Non LC subjects
      # @return [Boolean]
      def lc_subject_field?
        true
      end

      # Only some fields get delimiters before them in a standard LC Subject field
      def delimited_fields
        %w[v x y z]
      end

      # Most subject fields are constructed by joining together the alphabetic subfields
      # with either a '--' (before a $v, $x, $y, or $z) or a space (before everything else).
      # @return [String] An appropriately-delimited string
      def subject_string(padding: false)
        delimiter = _delimiter_string(padding)
        str = subject_data_subfield_codes.map do |sf|
          case sf.code
          when *delimited_fields
            "#{delimiter}#{sf.value}"
          else
            " #{sf.value}"
          end
        end.join("").gsub(/\A\s*#{delimiter}/, "") # pull off a leading delimiter if it's there

        normalize(str)
      end

      def _delimiter_string(padding)
        padding ? " #{default_delimiter} " : default_delimiter
      end
    end

    class LCSubject658 < LCSubject
      # Format taken from the MARC 658 documentation
      # @return [String] Subject string ready for output
      def subject_string(padding: false)
        delimiter = _delimiter_string(padding)
        str = subject_data_subfield_codes.map do |sf|
          case sf.code
          when "b"
            ": #{sf.value}"
          when "c"
            " [#{sf.value}]"
          when "d"
            # we do "--" instead of "-" because a single hyphen is too
            # confusing
            "#{delimiter}#{sf.value}"
          else
            " #{sf.value}"
          end
        end.join("").gsub(/\A\s*#{delimiter}/, "")
        normalize(str)
      end
    end

    # Purely hierarchical fields can just have all their parts
    # joined together with the delimiter
    class LCSubjectHierarchical < LCSubject
      # At least one subject field in LC, the 662, just gets delimiters everywhere
      # Format taken from the MARC 662 documentation
      # @return [String] Subject string ready for output
      def subject_string(padding: false)
        delimiter = _delimiter_string(padding)
        normalize(subject_data_subfield_codes.map(&:value).join(delimiter))
      end
    end

    # Taken from https://www.loc.gov/marc/bibliographic/bd752.html
    class LCAddedEntryHeirarchical < LCSubject
      def delimited_fields
        %w[a b c d e f g h]
      end

      def default_delimiter
        "-"
      end
    end
  end
end
