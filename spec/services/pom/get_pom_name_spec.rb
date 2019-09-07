require 'rails_helper'

describe POM::GetPomName do
  let(:staff_id) { 485_737 }

  before(:each) {
    PomDetail.create(nomis_staff_id: staff_id, working_pattern: 1.0, status: 'inactive')
  }

  describe '#get_pom_name' do
    it "can get staff names",
       vcr: { cassette_name: :pom_service_staff_name } do
      fname, lname = described_class.call(staff_id)
      expect(fname).to eq('JAY')
      expect(lname).to eq('HEAL')
    end
  end
end
