require "traject"
require "umich_traject"
describe Traject::UMich::ElectronicHolding do
  let(:e_resource) do
    get_record("./spec/fixtures/e_resource.xml")
  end
  let(:e56_1) do
    e_resource.fields("E56").first
  end
  let(:e56_2) do
    e_resource.fields("E56")[1]
  end
  let(:flint_campus) do
    @e56.append(MARC::Subfield.new("c", "UMFL"))
  end
  let(:ann_arbor_campus) do
    @e56.append(MARC::Subfield.new("c", "UMAA"))
  end
  before(:each) do
    @e56 = e56_1
    @e56.append(MARC::Subfield.new("z", "Public note:"))
    @e56.append(MARC::Subfield.new("3", "Description"))
  end
  subject do
    described_class.new(@e56)
  end
  context "#library" do
    it "shows ELEC" do
      expect(subject.library).to eq("ELEC")
    end
  end
  context "#link_text" do
    it "shows Available online" do
      expect(subject.link_text).to eq("Available online")
    end
  end
  context "#link" do
    it "returns the link with the Ann Arbor view when there are no campuses" do
      expect(subject.link).to include("openurl-UMAA")
    end
    it "returns the link with Ann Arbor view when both flint and ann arbor are campuses" do
      ann_arbor_campus
      flint_campus
      expect(subject.link).to include("openurl-UMAA")
    end
    it "returns the link with Ann Arbor view when only Ann Arbor is listed" do
      ann_arbor_campus
      expect(subject.link).to include("openurl-UMAA")
    end
    it "returns the link with Flint view when only Flint is listed" do
      flint_campus
      expect(subject.link).to include("openurl-UMFL")
    end
  end
  context "#institution_codes" do
    it "shows both insitutions,for no c code" do
      expect(subject.institution_codes).to eq(["MIU", "MIFLIC"])
    end
    it "shows both insitutions when both Flint and Ann Arbor are campuses " do
      ann_arbor_campus
      flint_campus
      expect(subject.institution_codes).to eq(["MIU", "MIFLIC"])
    end
    it "shows only MIU when only Ann Arbor is a listed campus" do
      ann_arbor_campus
      expect(subject.institution_codes).to eq(["MIU"])
    end
    it "shows only MIFLIC when only Flint is a listed campus" do
      flint_campus
      expect(subject.institution_codes).to eq(["MIFLIC"])
    end
  end
  context "#campuses" do
    it "shows both ann_arbor and flint when no c code" do
      expect(subject.campuses).to contain_exactly("ann_arbor", "flint")
    end
    it "shows both ann_arbor and flint when both UMAA and UMFL are present" do
      ann_arbor_campus
      flint_campus
      expect(subject.campuses).to contain_exactly("ann_arbor", "flint")
    end
    it "shows ann_arbor when c code is only UMAA" do
      ann_arbor_campus
      expect(subject.campuses).to contain_exactly("ann_arbor")
    end
    it "shows flint when c code is only UMFL" do
      flint_campus
      expect(subject.campuses).to contain_exactly("flint")
    end
  end
  context "#interface_name" do
    it "shows the interface from subfield m" do
      expect(subject.interface_name).to eq("Elsevier ScienceDirect")
    end
  end
  context "#public_note" do
    it "shows the public note from subfield z" do
      @e56.subfields.find { |x| x.code == "z" }.value = "Public note:"
      expect(subject.public_note).to eq("Public note:")
    end
  end
  context "#collection_name" do
    it "show the collection_name from subfield n" do
      expect(subject.collection_name).to eq("Elsevier SD eBook - Physics and Astronomy")
    end
    it "is an empty string if there is no collection name" do
      @e56.subfields.delete_if { |x| x.code == "n" }
      expect(subject.collection_name).to eq("")
    end
  end
  context "#authentication_note" do
    it "shows the authentication note from subfield 4" do
      expect(subject.authentication_note).to eq(["Authorized U-M users (+ guests in U-M Libraries)."])
    end
  end
  context "#note" do
    it "shows combined note" do
      expect(subject.note).to eq("Elsevier ScienceDirect. Elsevier SD eBook - Physics and Astronomy. Authorized U-M users (+ guests in U-M Libraries) Public note.")
    end
    it "handles concatenates with periods unless theres a ] or ) ending" do
      @e56.subfields.find { |x| x.code == "z" }.value = "(Parens)"
      @e56.subfields.find { |x| x.code == "4" }.value = "[Square]"
      @e56.subfields.find { |x| x.code == "n" }.value = "Ends in semicolon;"
      expect(subject.note).to eq("Elsevier ScienceDirect. Ends in semicolon. [Square] (Parens)")
    end

    it "handles empty collection_name field" do
      @e56.subfields.delete_if { |x| x.code == "n" }
      expect(subject.note).to eq("Elsevier ScienceDirect. Authorized U-M users (+ guests in U-M Libraries) Public note.")
    end
  end
  context "#status" do
    it "shows the status in subfield s" do
      expect(subject.status).to eq("Available")
    end
  end
  context "#description" do
    it "shows the description in subfield 3" do
      expect(subject.description).to eq("Description")
    end
  end
  context "#finding_aid" do
    it "is false" do
      expect(subject.finding_aid).to eq(false)
    end
  end
  context "#ranking" do
    it "gets the ranking from the translation map" do
      expect(subject.ranking).to eq(10100)
    end
    it "has a ranking of 99999 for items where the collection_id is not found" do
      @e56.subfields.find { |x| x.code == "k" }.value = "not_a_collection_id"
      expect(subject.ranking).to eq(99_999)
    end
  end
  context "#to_h" do
    it "returns expected hash" do
      s = subject
      expect(s.to_h).to eq(
        {
          "library" => s.library,
          "link" => s.link,
          "link_text" => s.link_text,
          "campuses" => s.campuses,
          "description" => s.description,
          "interface_name" => s.interface_name,
          "collection_name" => s.collection_name,
          "authentication_note" => s.authentication_note,
          "public_note" => s.public_note,
          "note" => s.note,
          "finding_aid" => false,
          "status" => s.status
        }
      )
    end
  end
end
