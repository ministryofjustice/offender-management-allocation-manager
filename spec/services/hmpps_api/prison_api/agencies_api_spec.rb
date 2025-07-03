require 'rails_helper'

describe HmppsApi::PrisonApi::AgenciesApi do
  let(:agency_type) { described_class::HOSPITAL_AGENCY_TYPE }

  before do
    stub_agencies(agency_type)
  end

  describe '#agencies_by_type' do
    it "returns array of agencies" do
      response = described_class.agencies_by_type(agency_type)

      expect(response).not_to be_nil
      expect(response).to be_instance_of(Array)
      expect(response).to include(include(agency_type: a_kind_of(String), description: a_kind_of(String), active: be_truthy))
    end
  end

  describe '#agency_ids_by_type' do
    it "returns array of agency IDs" do
      response = described_class.agency_ids_by_type(agency_type)

      expect(response).not_to be_nil
      expect(response).to be_instance_of(Array)
      expect(response).to include(a_kind_of(String))
    end
  end
end
