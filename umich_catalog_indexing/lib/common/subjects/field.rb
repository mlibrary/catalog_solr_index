module Common
  class Subjects
    class Field
      extend Forwardable
      attr_reader :normalized_sfs

      def_delegators :@field, :tag, :indicator2, :[], :subfields

      # @param field [MARC::DataField] A subject field from the bib record
      # @param remediation_map [Common::Subjects::RemediationMap] The
      # remediation rules based on the authority records
      # @param normalized_sfs [Array[String]] An array of the subfields in the field where the values have been normalized.
      def initialize(field:, remediation_map:, normalized_sfs: nil)
        @field = field
        @mapping = remediation_map.mapping
        @normalized_mapping = remediation_map.normalized_mapping
        @normalized_sfs = normalized_sfs
      end

      # Does the field need to be remediated? This is determined by checking if
      # the field matches a deprecated field in the authority record
      #
      # @return [Boolean]
      def remediable?
        !!_matching_deprecated_field
      end

      # Given a subject field, is it one that has already been remediated? This
      # is determined by checking if the field matches the preferred term in
      # the authority record
      #
      # @return [Boolean]
      def already_remediated?
        !!_matching_remediated_field
      end

      # Given a remediable field, return the remediated field
      #
      # @return [MARC::DataField] the remediated field
      def to_remediated
        match = _matching_deprecated_field

        sfields = @field.subfields.filter_map.with_index do |sf, index|
          unless match["normalized"]["450"][sf.code]
              &.include?(normalized_sfs[index]["value"])
            MARC::Subfield.new(sf.code, sf.value)
          end
        end

        remediated_field = MARC::DataField.new(@field.tag, @field.indicator1, "7", *sfields)
        match["given"]["150"].keys.each do |code|
          match["given"]["150"][code].each do |value|
            remediated_field.append(MARC::Subfield.new(code, value))
          end
        end
        remediated_field.subfields.sort_by!(&:code)
        remediated_field.append(MARC::Subfield.new("2", "miush"))

        remediated_field
      end

      # @return [Array<MARC::DataField>] the list of deprecated fields
      # generated because there were already remediated fields
      def to_deprecated
        match = _matching_remediated_field
        match["given"]["450"].map do |f|
          sfields = @field.subfields.filter_map.with_index do |sf, index|
            unless match["normalized"]["150"][sf.code]
                &.include?(normalized_sfs[index]["value"])
              MARC::Subfield.new(sf.code, sf.value)
            end
          end
          deprecated_field = MARC::DataField.new(@field.tag, @field.indicator1, @field.indicator2, *sfields)
          f.keys.each do |code|
            f[code].each do |value|
              deprecated_field.append(MARC::Subfield.new(code, value))
            end
          end
          deprecated_field.subfields.sort_by!(&:code)
          deprecated_field
        end
      end

      # @return [Hash, nil] the matching deprecated field information or nil
      def _matching_deprecated_field
        @_matching_deprecated_field ||= begin
          @mapping.each_with_index do |this_to_that, index|
            # Find the matching index of the 450 array where all of the
            # deprecated subfields are found in the bib record subject field
            dep_match_index = this_to_that["450"].index.with_index do |deprecated_subfields, dep_index|
              deprecated_subfields.keys.all? do |code|
                @normalized_mapping[index]["450"][dep_index][code].all? do |dep_sf_value|
                  _sf_in_field?(code: code, sf_value: dep_sf_value)
                end
              end
            end
            # If there's a matching subfield exit out of the loop and return all of the information
            unless dep_match_index.nil?
              return {
                "given" => {
                  "150" => this_to_that["150"],
                  "450" => @mapping[index]["450"][dep_match_index]
                },
                "normalized" => {
                  "150" => @normalized_mapping[index]["150"],
                  "450" => @normalized_mapping[index]["450"][dep_match_index]
                }
              }
            end
          end
          # otherwise return nil!
          nil
        end
      end

      # @return [Hash, nil] the matching remediated field information or nil.
      # Hash looks like { "given" => {}, "normalized" => {}}
      def _matching_remediated_field
        @_matching_remediated_field ||= begin
          # find the index in mapping where the field from the bib record contains all of the values
          index = @mapping.index.with_index do |this_to_that, i|
            this_to_that["150"].keys.all? do |code|
              @normalized_mapping[i]["150"][code].all? do |dep_sf_value|
                _sf_in_field?(code: code, sf_value: dep_sf_value)
              end
            end
          end
          # if there's a matching index return the mapping, otherwise nil
          unless index.nil?
            {
              "given" => @mapping[index],
              "normalized" => @normalized_mapping[index]
            }
          end
        end
      end

      def _sf_in_field?(code:, sf_value:)
        test_sf_values = normalized_sfs.filter_map do |sf|
          sf["value"] if sf["code"] == code
        end
        test_sf_values.include?(sf_value)
      end
    end
  end
end