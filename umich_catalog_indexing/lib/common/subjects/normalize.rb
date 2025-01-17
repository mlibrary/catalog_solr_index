# frozen_string_literal: true

module Common
  class Subjects
    module Normalize
      # This enables the use of the method Common::Subject::Normalize.normalize
      extend self

      # Mostly, we want to ditch punctuation, symbols, and spaces
      REMOVE = %q(\p{P}\p{S}\p{Z})

      # From the front of a string, we want to remove all punctuation and spaces except for
      # opening values (quotes, parens, etc.)
      FRONT_ALLOW = %q('"\p{Pi}\p{Ps})

      # On the back end, we'll allow closing quotes/parens and also allow a trailing
      # hyphen (for, e.g, "Bill Dueber 1969-")
      BACK_ALLOW = %q('"\p{Pe}\p{Pf}\p{Pd})

      # Put it all together into a regexp that removes the appropriate stuff from the
      # front and back of the string and captures whatever's left in the middle

      CLEANER = /\A[#{REMOVE}&&[^#{FRONT_ALLOW}]]*(.*?)[#{REMOVE}&&[^#{BACK_ALLOW}]]*\Z/

      # Normalization is just turning tabs into spaces and the applying the cleaner.
      def normalize(str)
        CLEANER.match(str.tr("\t", " "))[1]
      end
    end
  end
end
