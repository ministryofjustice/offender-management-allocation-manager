require 'rails_helper'

describe POM::GetPomsForPrison do
  let(:prison) { 'LEI' }

  describe '#get_poms' do
    it "can get a list of POMs",
       vcr: { cassette_name: :pom_service_get_poms_list } do
      poms = described_class.call(prison)
      expect(poms).to be_kind_of(Array)
      expect(poms.count).to eq(14)
    end

    it "can get a filtered list of POMs",
       vcr: { cassette_name: :pom_service_get_poms_filtered } do
      poms = described_class.call(prison).select { |pom|
        pom.status == 'active'
      }
      expect(poms).to be_kind_of(Array)
      expect(poms.count).to eq(14)
    end
  end
end
