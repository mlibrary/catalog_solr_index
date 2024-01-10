require "traject"
require 'umich_traject'

to_field "maisey_series", extract_marc("800fhklmnoprstv:810fhklmnoprstv:811fhklmnoprstv:830adfghklmnoprstv")

to_field "maisey_title", extract_marc("245abknp")

to_field "maisey_location" do |rec, acc|
  locations = rec.fields("974")&.map do |field|
    ::UMich::LibLocInfo.display_name(field["b"], field["e"])
  end
  locations.uniq!
  acc.replace locations
end

to_field "maisey_summary", extract_marc("520a")

to_field "maisey_contents", extract_marc("505at")
