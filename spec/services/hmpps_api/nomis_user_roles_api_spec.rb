require 'rails_helper'

describe HmppsApi::NomisUserRolesApi do
  let(:staff_id) { 485_636 }
  let(:username) { 'MOIC_POM' }

  describe '.staff_details' do
    let(:pom) { build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com') }

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

    describe '.email_address' do
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

  describe '.get_users' do
    let(:caseload) { 'LEI' }
    let(:filter) { 'Smith' }
    let(:response_body) do
      {
        'totalElements' => 1,
        'content' => [
          {
            'staffId' => 123_456,
            'username' => 'SMITH_J',
            'firstName' => 'JOHN',
            'lastName' => 'SMITH',
            'email' => 'test@example.com'
          }
        ]
      }
    end

    before do
      stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users")
        .with(
          query: {
            caseload: caseload,
            nameFilter: 'smith',
            userType: 'GENERAL',
            status: 'ACTIVE',
            accessRoles: 'ALLOC_CASE_MGR',
            size: 100
          }
        ).to_return(body: response_body.to_json)
    end

    it 'returns users matching the search criteria' do
      response = described_class.get_users(caseload:, filter:)

      expect(response['content'].first).to include(
        'staffId' => 123_456,
        'username' => 'SMITH_J'
      )
    end
  end

  describe '.set_staff_role' do
    let(:agency_id) { 'LEI' }
    let(:role_params) do
      {
        position: 'POM',
        schedule_type: 'FT',
        hours_per_week: 37.5
      }
    end

    before do
      stub_request(:put, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/agency/#{agency_id}/staff-members/#{staff_id}/staff-role/POM")
        .with(
          body: {
            fromDate: Time.zone.today,
            position: 'POM',
            scheduleType: 'FT',
            hoursPerWeek: 37.5
          }.to_json
        ).to_return(status: 200, body: {}.to_json)
    end

    it 'sets the staff role with the provided parameters' do
      expect {
        described_class.set_staff_role(agency_id, staff_id, **role_params)
      }.not_to raise_error
    end
  end

  describe '.expire_staff_role' do
    let(:pom) do
      instance_double(
        HmppsApi::PrisonOffenderManager,
        agency_id: 'LEI',
        staff_id: 123_456,
        position: 'POM',
        schedule_type: 'FT',
        hours_per_week: 37.5,
        from_date: 1.month.ago,
      )
    end

    before do
      stub_request(:put, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/agency/#{pom.agency_id}/staff-members/#{pom.staff_id}/staff-role/POM")
        .with(
          body: {
            toDate: Time.zone.yesterday,
            fromDate: pom.from_date,
            position: pom.position,
            scheduleType: pom.schedule_type,
            hoursPerWeek: pom.hours_per_week
          }.to_json
        ).to_return(status: 200, body: {}.to_json)
    end

    it 'expires the staff role for the given POM' do
      expect {
        described_class.expire_staff_role(pom)
      }.not_to raise_error
    end
  end
end
