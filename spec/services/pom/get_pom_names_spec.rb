require 'rails_helper'

describe POM::GetPomNames do
  let(:prison) { 'LEI' }

  describe '#get_pom_names' do
    it "can get the names for POMs when given IDs",
       vcr: { cassette_name: :pom_service_get_poms_by_ids } do
      names = described_class.call(prison)
      expect(names).to be_kind_of(Hash)
      expect(names.count).to eq(13)
    end
  end
end
