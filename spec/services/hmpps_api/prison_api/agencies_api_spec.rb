require 'rails_helper'

describe HmppsApi::PrisonApi::AgenciesApi do
  describe '#agencies_by_type' do
    it "returns array of agencies", vcr: { cassette_name: 'prison_api/agencies_api' } do
      response = described_class.agencies_by_type(described_class::HOSPITAL_AGENCY_TYPE)

      expect(response).not_to be_nil
      expect(response).to be_instance_of(Array)
      expect(response).to include(include(agency_type: a_kind_of(String), description: a_kind_of(String), active: be_truthy))
    end
  end

  describe '#agency_ids_by_type' do
    it "returns array of agency IDs", vcr: { cassette_name: 'prison_api/agencies_api' } do
      response = described_class.agency_ids_by_type(described_class::HOSPITAL_AGENCY_TYPE)

      expect(response).not_to be_nil
      expect(response).to be_instance_of(Array)
      expect(response).to include(a_kind_of(String))
    end
  end
end
