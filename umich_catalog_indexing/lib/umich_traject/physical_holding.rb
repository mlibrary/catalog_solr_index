module Traject
  module UMich
    class PhysicalHolding
      attr_reader :holding_id

      def initialize(record:, holding_id:)
        @holding_id = holding_id
        @record = record
      end

      def institution_code
        f852["a"]&.upcase
      end

      def summary_holdings
        output = []
        @record.each_by_tag("866") do |f|
          output.push(f["a"]) if f["8"] == holding_id
        end
        str = output.join(" : ")
        (str == "") ? nil : str
      end

      # An array of PhysicalItem objects with enumcron sorting and not including
      # the suppressed items
      #
      # @return [Array] array of PhysicalItem objects
      def items
        @items ||= Traject::UMich::EnumcronSorter.sort(
          f974.map do |i|
            Traject::UMich::PhysicalItem.new(item: i, has_finding_aid: finding_aid?)
          end.reject do |x|
            x.should_be_suppressed
          end
        )
      end

      def callnumber
        f852["h"]
      end

      def display_name
        ::UMich::LibLocInfo.display_name(library, location)
      end

      def floor_location
        return "" if callnumber.nil?
        ::UMich::FloorLocation.resolve(library, location, callnumber)
      end

      def info_link
        ::UMich::LibLocInfo.info_link(library, location)
      end

      def library
        f852["b"]
      end

      def location
        f852["c"]
      end

      # Summary of all locations associated with a given holding. This includes
      # locations in the 852 field and locations (both permanant and temporary)
      # in the 974 item field. This gets added to the "locations" solr field.
      #
      # @return [Array] an array of library codes and "library location" codes
      def locations
        [library, "#{library} #{location}".strip].push(items.map { |x| x.locations }).flatten.uniq
      end

      def circulating?
        items.any? { |x| x.circulating? }
      end

      def public_note
        f852.filter_map { |x| x.value if x.code == "z" }
      end

      def field_is_finding_aid?(f)
        link_text = f["y"]
        link = f["u"]
        link_text =~ /finding aid/i and link =~ /umich/i
      end

      # Checks whether there exists a finding aid in the 856 field
      #
      # @return [Boolean] whether or not the 856 has a a finding aid
      def finding_aid?
        @record.fields("856").any? { |f| field_is_finding_aid?(f) }
      end

      # Hash summary of what is in the holding. This is what is added to the
      # "hol" solr field
      #
      # @returns [Hash] summary of the item
      def to_h
        {
          hol_mmsid: holding_id,
          callnumber: callnumber,
          library: library,
          location: location,
          info_link: info_link,
          display_name: display_name,
          floor_location: floor_location,
          public_note: public_note,
          items: items.map { |x| x.to_h },
          summary_holdings: summary_holdings,
          record_has_finding_aid: finding_aid?
        }
      end

      # A FieldMap of the 852 fields assosiated with this holding_id
      #
      # @return [MARC::FieldMap] an array-like set of MARC::DataField objects
      def f852
        @f852 ||= @record.fields("852").find { |f| f["8"] == @holding_id }
      end

      # A FieldMap of the 974 fields assosiated with this holding_id
      #
      # @return [MARC::FieldMap] an array-like set of MARC::DataField objects
      def f974
        @f974 ||= @record.fields("974").select { |f| f["8"] == @holding_id }
      end
    end
  end
end
