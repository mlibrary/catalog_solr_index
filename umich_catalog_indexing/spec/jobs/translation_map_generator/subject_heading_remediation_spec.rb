require_relative "../../spec_helper"
require "jobs"

describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToDeprecated do
  before(:each) do
    @data = {
      "illegal aliens" => "Undocumented immigrants",
      "aliens" => "Undocumented immigrants",
      "aliens, illegal" => "Undocumented immigrants",
      "illegal immigrants" => "Undocumented immigrants",
      "children of illegal aliens" => "Children of undocumented immigrants"
    }
  end
  context ".reverse_it" do
    it "reverses the input, using pipes as delimeters" do
      expect(described_class.reverse_it(@data)).to eq({
        "undocumented immigrants" => "illegal aliens||aliens||aliens, illegal||illegal immigrants",
        "children of undocumented immigrants" => "children of illegal aliens"
      })
    end
  end
end
describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Set do
  before(:each) do
    @data = fixture("authority_set.json")
  end
  let(:set_id) { "1234" }
  let(:authority_record_id) { "98187481368106381" }
  let(:authority_record) { fixture("remediated_authority_record.json") }
  let(:second_authority_record_id) { "999" }
  let(:second_authority_record) { fixture("remediated_authority_record2.json") }
  let(:stub_set_request) {
    stub_alma_get_request(
      url: "conf/sets/#{set_id}/members",
      query: {limit: 100, offset: 0},
      output: @data
    )
  }
  let(:stub_authority_request) {
    stub_alma_get_request(
      url: "bibs/authorities/#{authority_record_id}",
      query: {view: "full"},
      output: authority_record
    )
  }
  let(:stub_second_authority_request) {
    stub_alma_get_request(
      url: "bibs/authorities/#{second_authority_record_id}",
      query: {view: "full"},
      output: second_authority_record
    )
  }
  subject do
    described_class.new(JSON.parse(@data))
  end
  context "#ids" do
    it "returns an array of ids" do
      expect(subject.ids).to contain_exactly(authority_record_id)
    end
  end

  context "#authority_records" do
    it "returns an array of Authority objects" do
      stub_authority_request
      expect(subject.authority_records.first.remediated_term).to eq("Undocumented immigrants")
    end
  end

  context "#to_h" do
    it "returns a flattend hash of the array of authority objects" do
      # Add an extra member to json
      d = JSON.parse(@data)
      d["member"].push({"id" => "999", "description" => "string"})
      @data = d.to_json
      stub_authority_request
      stub_second_authority_request

      expect(subject.to_h).to eq({
        "undocumented foreign nationals" => "Undocumented immigrants",
        "illegal aliens" => "Undocumented immigrants",
        "aliens" => "Undocumented immigrants",
        "aliens, illegal" => "Undocumented immigrants",
        "illegal immigrants" => "Undocumented immigrants",
        "undocumented noncitizens" => "Undocumented immigrants",
        "stuff" => "Whatever"
      })
    end
  end
  context ".for" do
    it "returns a Set from the Alma Set id" do
      stub_set_request
      expect(described_class.for(set_id).ids.first).to eq(authority_record_id)
    end
    it "errors out if it can't talk to alma" do
      stub_alma_get_request(
        url: "conf/sets/#{set_id}/members",
        query: {limit: 100, offset: 0},
        no_return: true
      ).to_timeout
      expect { described_class.for(set_id) }.to raise_error(StandardError, /#{set_id}/)
    end
  end
end
describe Jobs::TranslationMapGenerator::SubjectHeadingRemediation::ToRemediated::Authority do
  before(:each) do
    @data = JSON.parse(fixture("remediated_authority_record.json"))
  end
  subject do
    described_class.new(@data)
  end
  let(:authority_record_id) { "12345" }
  context ".for" do
    it "errors out if it can't talk to Alma" do
      stub_alma_get_request(
        url: "bibs/authorities/#{authority_record_id}",
        query: {view: "full"},
        status: 500
      )
      expect { described_class.for(authority_record_id) }.to raise_error(StandardError, /#{authority_record_id}/)
    end
  end
  context "#remeidated_term" do
    it "returns the remediated term" do
      expect(subject.remediated_term).to eq("Undocumented immigrants")
    end
  end
  context "#deprecated_terms" do
    it "returns the deprecated terms from the 450 field" do
      expect(subject.deprecated_terms).to contain_exactly(
        "Undocumented foreign nationals",
        "Illegal aliens",
        "Aliens",
        "Aliens, Illegal",
        "Illegal immigrants",
        "Undocumented noncitizens"
      )
    end
  end
  context "#to_h" do
    it "returns the expected deprecated_to_remediated hash with downcased terms" do
      expect(subject.to_h).to eq({
        "undocumented foreign nationals" => "Undocumented immigrants",
        "illegal aliens" => "Undocumented immigrants",
        "aliens" => "Undocumented immigrants",
        "aliens, illegal" => "Undocumented immigrants",
        "illegal immigrants" => "Undocumented immigrants",
        "undocumented noncitizens" => "Undocumented immigrants"
      })
    end
  end
end