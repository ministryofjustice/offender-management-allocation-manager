require 'rails_helper'

describe Nomis::Custody::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  around do |ex|
    travel_to Date.new(2019, 1, 4, 13) do
      ex.run
    end
  end

  it "gets staff details",
    vcr: { cassette_name: :get_nomis_staff_details } do
    username = 'PK000223'

    response = described_class.fetch_nomis_staff_details(username)

    expect(response.data).to be_kind_of(Nomis::StaffDetails)
    expect(response.data.active_nomis_caseload).to eq('LEI')
  end

  it 'gets prisoner information for a particular prison',
    vcr: { cassette_name: :get_prisoners } do
    prison = 'LEI'

    response = described_class.get_offenders(prison)

    expect(response.data.count).to eq(10)
    expect(response.data.first).to be_kind_of(Nomis::OffenderDetails)
    expect(response.meta).to be_kind_of(PageMeta)
  end

  it 'does not explode with a bad page number',
    :raven_intercept_exception,
    vcr: { cassette_name: :get_prisoners_bad_page } do
    prison = 'LEI'

    response = described_class.get_offenders(prison, 10_000)

    expect(response.data.count).to eq(0)
    expect(response.meta).to be_kind_of(PageMeta)
  end

  it 'gets release details for a prisoner',
    vcr: { cassette_name: :get_release_details } do
      offender_id = '1317074'
      booking_id = '965725'

      response = described_class.get_release_details(offender_id, booking_id)

      expect(response.data).to be_instance_of(Nomis::ReleaseDetails)
      expect(response.data.release_date).to eq('2017-04-09')
    end

  it 'returns a NullReleaseDetails if there are no release details for a prisoner', :raven_intercept_exception,
    vcr: { cassette_name: :handle_null_release_details } do
      offender_id = '1027417'
      booking_id = '1142296'

      response = described_class.get_release_details(offender_id, booking_id)

      expect(response.data).to be_instance_of(Nomis::NullReleaseDetails)
    end
end
