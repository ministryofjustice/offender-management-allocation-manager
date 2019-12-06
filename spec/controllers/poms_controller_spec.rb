require 'rails_helper'

RSpec.describe PomsController, type: :controller do
  let(:prison) { build(:prison) }

  before do
    stub_sso_data(prison.code)
    inactive = create(:pom_detail, :inactive)
    active = create(:pom_detail, :active)
    unavailable = create(:pom_detail, :unavailable)
    stub_poms(prison.code, [
      build(:pom, staffId: inactive.nomis_staff_id),
      build(:pom, staffId: active.nomis_staff_id),
      build(:pom, staffId: unavailable.nomis_staff_id)
    ])
    create(:allocation, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    create(:allocation, primary_pom_nomis_id: inactive.nomis_staff_id, secondary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
  end

  render_views

  it 'shows the correct counts on index' do
    get :index, params: { prison_id: prison.code }

    expect(response).to be_successful

    expect(assigns(:inactive_poms).count).to eq(1)
    expect(assigns(:active_poms).count).to eq(2)

    active_pom = assigns(:active_poms).detect { |pom| pom.status == 'active' }
    # one primary, one co-working
    expect(active_pom.total_cases).to eq(2)
  end

  context 'when showing caseload' do
    let(:staff_id) { PomDetail.where(status: 'active').first!.nomis_staff_id }
    let(:offenderNos) { Allocation.all.map(&:nomis_offender_id).reverse }

    before do
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/#{staff_id}").
        to_return(status: 200, body: { staffId: staff_id, lastName: 'LastName', firstName: 'FirstName' }.to_json, headers: {})

      offenders = [
        { "latestBookingId": 754_207, "offenderNo": offenderNos.first, "firstName": "Alice", "lastName": "Aliceson",
          "dateOfBirth": "1990-12-06", "age": 28, "categoryCode": "C", "imprisonmentStatus": "LIFE",
          "convictedStatus": "Convicted", "latestLocationId": prison.code },
        { "latestBookingId": 754_206, "offenderNo": offenderNos.last, "firstName": "Bob", "lastName": "Bibby",
          "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison.code, "categoryCode": "D", "imprisonmentStatus": "SENT03",
          "convictedStatus": "Convicted", "latestLocationId": prison.code }
      ]

      bookings = [
        { "bookingId": 754_207, "offenderNo": offenderNos.first, "firstName": "Indeter", "lastName": "Minate-Offender", "agencyLocationId": prison.code,
          "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                              "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                              "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                              "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                              "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
          "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
        { "bookingId": 754_206, "offenderNo": offenderNos.last, "firstName": "ROSS", "lastName": "JONES", "agencyLocationId": prison.code,
          "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                              "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                              "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                              "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                              "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
          "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }
      ]

      stub_multiple_offenders(offenders, bookings)
    end

    it 'shows the caseload on the show action' do
      get :show, params: { prison_id: prison.code, nomis_staff_id: staff_id }
      expect(response).to be_successful
      expect(assigns(:allocations).count).to eq(2)
    end
  end
end
