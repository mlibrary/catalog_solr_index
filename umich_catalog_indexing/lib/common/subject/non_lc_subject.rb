# frozen_string_literal: true

require_relative "lc_subject"

module Common::Subject
  # There are a wide variety of non-LC subject types (e.g., MESH). For the
  # moment, just treat them all the same as LC Hierarchical, with delimiters
  # between every subfield value
  class NonLCSubject < Common::Subject::LCSubjectHierarchical

    # Here for testing purposes to distinguish from the LC subjects
    # @return [Boolean]
    def lc_subject_field? 
      false
    end

  end
end