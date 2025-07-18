require 'rails_helper'

describe HmppsApi::NomisUserRolesApi do
  let(:staff_id) { 485_636 }
  let(:username) { 'MOIC_POM' }
  let(:pom) { build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com') }

  describe '.staff_details' do
    before do
      stub_pom(pom)
    end

    it 'gets the staff details' do
      response = described_class.staff_details(staff_id)

      expect(response.staff_id).to eq(staff_id)
      expect(response.first_name).to eq("MOIC")
      expect(response.last_name).to eq("POM")
      expect(response.status).to eq("ACTIVE")
      expect(response.email_address).to eq("test@example.com")
    end

    context '.email_address' do
      it "can get a user's email addresses" do
        response = described_class.email_address(staff_id)
        expect(response).to eq('test@example.com')
      end
    end
  end

  describe '.user_details' do
    before do
      stub_user(username, staff_id)
    end

    it 'gets the user details' do
      response = described_class.user_details(username)

      expect(response.staff_id).to eq(staff_id)
      expect(response.first_name).to eq("MOIC")
      expect(response.last_name).to eq("POM")
      expect(response.email_address).to eq("user@example.com")
    end
  end
end
