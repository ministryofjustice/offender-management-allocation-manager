require 'rails_helper'

RSpec.describe SummaryController, type: :controller do
  let(:prison) { 'LEI' }

  before do
    stub_sso_data(prison)

    offenders = [
      { "bookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Indeter", "lastName": "Minate-Offender",
        "dateOfBirth": "1990-12-06", "age": 28, "agencyId": prison, "categoryCode": "C", "imprisonmentStatus": "LIFE" },
      { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "ROSS", "lastName": "JONES",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" },
      { "bookingId": 1, "offenderNo": "G1234XX", "firstName": "BOB", "lastName": "SMITH",
        "dateOfBirth": "1995-02-02", "age": 34, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "LR" }
    ]

    bookings = [
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
      with(body: "[\"G7514GW\",\"G1234VV\"]").
      to_return(status: 200, body: [{ offenderNo: 'G7514GW', toAgency: prison, createDateTime: Date.new(2018, 10, 1) },
                                    { offenderNo: 'G1234VV', toAgency: prison, createDateTime: Date.new(2018, 9, 1) }].to_json)
  end

  it 'gets pending records' do
    get :pending, params: { prison_id: prison }
    # Expecting offender (2) to use sentenceStartDate as it is newer than last arrival date in prison
    expect(assigns(:summary).offenders.map(&:awaiting_allocation_for).map { |x| Time.zone.today - x }).
      to match_array [Date.new(2018, 10, 1), Date.new(2019, 2, 8)]
  end
end
