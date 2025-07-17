require 'rails_helper'

describe HmppsApi::NomisUserRolesApi do
  let(:staff_id) { 485_636 }
  let(:pom) { build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com') }

  before do
    stub_poms('LEI', [pom])
  end

  describe '.staff_details' do
    it 'gets staff detail' do
      response = described_class.staff_details(staff_id)

      expect(response.staff_id).to eq(staff_id)
      expect(response.first_name).to eq("MOIC")
      expect(response.last_name).to eq("POM")
      expect(response.status).to eq("ACTIVE")
      expect(response.email_address).to eq("test@example.com")
    end
  end

  describe '.email_address' do
    it "can get a user's email addresses" do
      response = described_class.email_address(staff_id)
      expect(response).to eq('test@example.com')
    end
  end
end
