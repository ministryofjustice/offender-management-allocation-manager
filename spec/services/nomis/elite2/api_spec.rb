require 'rails_helper'

describe Nomis::Elite2::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  describe 'List of offenders' do
    it "can get a list of offenders",
      vcr: { cassette_name: :get_elite2_offender_list } do
      response = described_class.get_offender_list('LEI')

      expect(response).not_to be_nil
      expect(response.data).to be_instance_of(Array)
      expect(response.data).to all(be_an Nomis::Elite2::OffenderShort)
    end

    it "can get an offence description for a booking id",
      vcr: { cassette_name: :get_offence_ok } do
      booking_id = '1153753'
      response = described_class.get_offence(booking_id)
      expect(response.data).to be_instance_of(String)
      expect(response.data).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
    end
  end

  describe 'Single offender' do
    it "can get a single offender's details", vcr: { cassette_name: :full_single_offender } do
      noms_id = 'G2911GD'

      response = described_class.get_offender(noms_id)

      expect(response.data).to be_instance_of(Nomis::Elite2::Offender)
    end

    it 'returns null if unable to find prisoner', :raven_intercept_exception,
      vcr: { cassette_name: :elite2_api_fail_get_offender_details } do
      noms_id = 'AAA22D'

      response = described_class.get_offender(noms_id)

      expect(response.data).to be_instance_of(Nomis::Elite2::NullOffender)
    end
  end

  describe 'Staff' do
    # Note we are temporarily getting POMs from keyworker
    it 'can get a of Prison Offender Managers (POMs)',
      vcr: { cassette_name: :get_elite2_keyworkers } do
      response = described_class.prisoner_offender_manager_list('LEI')

      expect(response.data).to be_instance_of(Array)
      expect(response.data).to all(be_an Nomis::Elite2::PrisonerOffenderManager)
    end

    it "gets staff details",
      vcr: { cassette_name: :elite2_api_get_nomis_user_details } do
      username = 'PK000223'

      response = described_class.fetch_nomis_user_details(username)

      expect(response.data).to be_kind_of(Nomis::Elite2::UserDetails)
      expect(response.data.active_case_load_id).to eq('LEI')
    end
  end
end
