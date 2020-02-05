require 'rails_helper'

RSpec.describe DebuggingController, type: :controller do
  let(:prison) { 'WEI' }
  let(:booking_id) { 'booking3' }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
  let(:elite2listapi) { "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true" }
  let(:elite2bookingsapi) { "#{elite2api}/offender-sentences/bookings" }

  before do
    stub_sso_data(prison, 'user')
    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/movements/offenders?latestOnly=false&movementTypes=TRN").
      with(
        body: "[\"G7806VO\"]",
        headers: {
          'Authorization' => 'Bearer token',
          'Content-Type' => 'application/json',
          'Expect' => '',
          'User-Agent' => 'Faraday v0.15.4'
        }).
      to_return(status: 200, body: [].to_json, headers: {})
  end

  context 'when debugging at a prison level' do
    it 'can show debugging information for an entire prison' do
      stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/movements/offenders?latestOnly=false&movementTypes=TRN").
      to_return(status: 200, body: [].to_json)
      stub_request(:get, elite2listapi).
          with(
            headers: {
              'Page-Limit' => '1',
              'Page-Offset' => '1'
            }).
          to_return(status: 200, body: {}.to_json, headers: { 'Total-Records' => '3' })

      stub_request(:get, elite2listapi).
          with(
            headers: {
              'Page-Limit' => '200',
              'Page-Offset' => '200'
            }).
          to_return(status: 200, body: {}.to_json, headers: { 'Total-Records' => '3' })

      stub_request(:get, elite2listapi).
          with(
            headers: {
              'Page-Limit' => '200',
              'Page-Offset' => '0'
            }).
          to_return(status: 200,
                    body: [{ "bookingId": 754_207, "bookingNo": "K09211", "offenderNo": "G7806VO", "firstName": "ONGMETAIN",
                             "lastName": "ABDORIA", "dateOfBirth": "1990-12-06",
                             "age": 28, "agencyId": "WEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                             "facialImageId": 1_392_829,
                             "categoryCode": "C", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" },
                           { "bookingId": 754_206, "bookingNo": "K09212", "offenderNo": "G1234VV", "firstName": "ROSS",
                             "lastName": "JONES", "dateOfBirth": "2004-02-02",
                             "age": 15, "agencyId": "WEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                             "facialImageId": 1_392_900,
                             "categoryCode": "D", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" },
                           { "bookingId": 1, "bookingNo": "K09213", "offenderNo": "G1234XX", "firstName": "BOB",
                             "lastName": "SMITH", "dateOfBirth": "1995-02-02",
                             "age": 34, "agencyId": "WEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                             "facialImageId": 1_392_900,
                             "categoryCode": "D", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" }
                    ].to_json)
      stub_request(:post, elite2bookingsapi).
          with(body: "[754207,754206,1]").
          to_return(status: 200, body: [
              { "bookingId": 754_207, "offenderNo": "G4912VX", "firstName": "EASTZO", "lastName": "AUBUEL", "agencyLocationId": "WEI",
                "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                                    "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                                    "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                                    "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                                    "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
                "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
              { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "ROSS", "lastName": "JONES", "agencyLocationId": "WEI",
                "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                                    "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                                    "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                                    "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                                    "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
                "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }
          ].to_json, headers: {})

      get :prison_info, params: { prison_id: prison }
      expect(response.status).to eq(200)
      expect(response).to be_successful

      expect(assigns(:prison_title)).to eq('HMP Wealstun')
      expect(assigns(:filtered_offenders_count)).to eq(1)
      expect(assigns(:unfiltered_offenders_count)).to eq(3)

      filtered_offenders = assigns(:filtered)
      expect(filtered_offenders[:under18].count).to eq(1)
      expect(filtered_offenders[:under18].first.first_name).to eq("ROSS")
      expect(filtered_offenders[:unsentenced].count).to eq(1)

      summary = assigns(:summary)
      expect(summary.allocated.count).to eq(0)
      expect(summary.unallocated.count).to eq(0)
      expect(summary.pending.count).to eq(1)
    end
  end

  context 'when debugging an offender' do
    let(:offender_no) { 'G7806VO' }
    let(:pom_staff_id) { 543_453 }
    let(:primary_pom_name) { 'Jenae Sporer' }

    it 'can show debugging information for a specific offender' do
      stub_offender(offender_no, imprisonment_status: 'LIFE')

      stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/movements/offenders?movementTypes=ADM&movementTypes=TRN&movementTypes=REL&latestOnly=false").
        with(
          body: "[\"G7806VO\"]").
          to_return(status: 200, body: [{ offenderNo: offender_no,
                                          fromAgency: "LEI",
                                          toAgency: "WEI",
                                          movementType: "TRN",
                                          directionCode: "IN" }].to_json, headers: {})

      create(:case_information, nomis_offender_id: offender_no)
      create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: pom_staff_id, primary_pom_name: primary_pom_name)

      get :debugging, params: { prison_id: prison, offender_no: offender_no }

      expect(response.status).to eq(200)
      expect(response).to be_successful
      expect(response).to render_template("debugging/debugging")

      offender = assigns(:offender)
      expect(offender.indeterminate_sentence?).to be true

      allocation = assigns(:allocation)
      expect(allocation.primary_pom_name).to eq primary_pom_name

      override = assigns(:override)
      expect(override).to eq nil

      movements = assigns(:movements)
      expect(movements.movement_type).to eq "TRN"
      expect(movements.from_agency).to eq "LEI"
      expect(movements.to_agency).to eq "WEI"
    end
  end
end
