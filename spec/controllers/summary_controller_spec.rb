require 'rails_helper'

RSpec.describe SummaryController, type: :controller do
  let(:prison) { 'LEI' }
  let(:poms) {
    [
      {
        firstName: 'Alice',
        position: RecommendationService::PRISON_POM,
        staffId: 1
      }
    ]
  }

  before do
    stub_sso_data(prison)

    offenders = [
      { "bookingId": 754_208, "offenderNo": "G1234GY", "firstName": "BOB", "lastName": "SMITH",
        "dateOfBirth": "1995-02-02", "age": 34, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "LR" },
      { "bookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Indeter", "lastName": "Minate-Offender",
        "dateOfBirth": "1990-12-06", "age": 28, "agencyId": prison, "categoryCode": "C", "imprisonmentStatus": "LIFE" },
      { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "ROSS", "lastName": "JONES",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" }
    ]

    bookings = [
      { "bookingId": 754_208, "offenderNo": "G7514GW", "firstName": "Indeter", "lastName": "Minate-Offender", "agencyLocationId": prison,
        "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                            "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                            "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                            "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                            "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
        "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
      { "bookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Indeter", "lastName": "Minate-Offender", "agencyLocationId": prison,
        "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                            "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                            "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                            "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                            "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
        "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
      { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "ROSS", "lastName": "JONES", "agencyLocationId": prison,
        "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                            "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                            "bookingId": 754_207, "sentenceStartDate": "2019-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                            "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                            "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
        "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }
    ]

    stub_offenders_for_prison(prison, offenders, bookings)

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/movements/offenders?latestOnly=false&movementTypes=TRN").
      with(body: %w[G1234GY G7514GW G1234VV].to_json).
      to_return(status: 200, body: [{ offenderNo: 'G7514GW', toAgency: prison, createDateTime: Date.new(2018, 10, 1) },
                                    { offenderNo: 'G1234VV', toAgency: prison, createDateTime: Date.new(2018, 9, 1) }].to_json)
  end

  context 'when user is a POM' do
    before do
      stub_poms(prison, poms)
      stub_sso_pom_data(prison)
      stub_signed_in_pom(1, 'Alice')
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/").
        with(headers: { 'Authorization' => 'Bearer token' }).
        to_return(status: 200, body: { staffId: 1 }.to_json, headers: {})
    end

    it 'is not visible' do
      get :pending, params: { prison_id: prison }
      expect(response).to redirect_to('/')
    end
  end

  it 'gets pending records' do
    get :pending, params: { prison_id: prison }
    # Expecting offender (2) to use sentenceStartDate as it is newer than last arrival date in prison
    expect(assigns(:summary).offenders.map(&:awaiting_allocation_for).map { |x| Time.zone.today - x }).
      to match_array [Date.new(2009, 2, 8), Date.new(2018, 10, 1), Date.new(2019, 2, 8)]
  end

  it 'handles trying to sort by missing field for allocated offenders' do
    # When viewing allocated, cannot sort by awaiting_allocation_for as it is not available and is
    # meaningless in this context. We do not want to crash if passed a field that is not searchable
    # within a specific context.
    offender_id = 'G7514GW'
    offenders = [{ "bookingId": 754_207, "offenderNo": offender_id, "firstName": "Indeter", "lastName": "Minate-Offender",
                   "dateOfBirth": "1990-12-06", "age": 28, "agencyId": prison, "categoryCode": "C", "imprisonmentStatus": "LIFE" }]

    bookings = [{ "bookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Indeter", "lastName": "Minate-Offender", "agencyLocationId": prison,
                  "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                                      "bookingId": 754_207, "sentenceStartDate": "2009-02-08",
                                      "releaseDate": "2012-03-17" },
                  "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
                  "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }]
    stub_offenders_for_prison(prison, offenders, bookings)

    create(:case_information, nomis_offender_id: offender_id)
    create(:allocation_version, nomis_offender_id: offender_id, primary_pom_nomis_id: 234)

    get :allocated, params: { prison_id: prison, sort: 'awaiting_allocation_for asc' }
    expect(assigns(:summary).offenders.count).to eq(1)
  end
end
