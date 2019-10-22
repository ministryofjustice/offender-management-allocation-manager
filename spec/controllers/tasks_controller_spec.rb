require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  let(:prison) { 'LEI' }
  let(:staff_id) { 123 }
  let(:username) { 'alice' }
  let(:pom) {
    [
      {
        staffId: staff_id,
        username: username,
        position: 'PRO'
      }
    ]
  }

  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
  let(:elite2listapi) { "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true" }
  let(:elite2bookingsapi) { "#{elite2api}/offender-sentences/bookings" }

  before do
    stub_sso_pom_data(prison)

    stub_poms(prison, pom)
    stub_signed_in_pom(staff_id, username)

    offenders = [
      { "bookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Indeter", "lastName": "Minate-Offender",
        "dateOfBirth": "1990-12-06", "age": 28, "agencyId": prison, "categoryCode": "C", "imprisonmentStatus": "LIFE" },
      { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "ROSS", "lastName": "JONES",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" },
      { "bookingId": 754_205, "offenderNo": "G1234AB", "firstName": "ROSS", "lastName": "JONES",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" },
      { "bookingId": 754_204, "offenderNo": "G1234GG", "firstName": "ROSS", "lastName": "JONES",
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
                            "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                            "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                            "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
        "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
      { "bookingId": 754_205, "offenderNo": "G1234AB", "firstName": "ROSS", "lastName": "JONES", "agencyLocationId": prison,
        "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                            "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                            "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                            "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                            "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
        "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 },
      { "bookingId": 754_204, "offenderNo": "G1234GG", "firstName": "ROSS", "lastName": "JONES", "agencyLocationId": prison,
        "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                            "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                            "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                            "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                            "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
        "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }
    ]

    stub_offenders_for_prison(prison, offenders, bookings)
  end

  before do
    allow_any_instance_of(described_class).to receive(:current_user).and_return('alice')
  end

  context 'when showing parole review date pom tasks' do
    let(:offender_no) { 'G7514GW' }

    it 'can show offenders needing parole review date updates' do
      stub_offender(offender_no, booking_number: 754_207, imprisonment_status: 'LIFE')

      create(:case_information, nomis_offender_id: offender_no, tier: 'A')
      create(:allocation_version, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)
      expect(pomtasks.first.offender_number).to eq(offender_no)
      expect(pomtasks.first.action_label).to eq('Parole review date')
    end
  end

  context 'when showing ndelius update pom tasks' do
    let(:offender_no) { 'G1234VV' }

    it 'can show offenders needing nDelius updates' do
      stub_offender(offender_no, booking_number: 754_206)

      create(:case_information, nomis_offender_id: offender_no, tier: 'A', local_divisional_unit: nil)
      create(:allocation_version, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)
      expect(pomtasks.first.offender_number).to eq(offender_no)
      expect(pomtasks.first.action_label).to eq('nDelius case matching')
    end
  end

  context 'when showing early allocation decisions required' do
    let(:offender_nos) { %w[G1234AB G1234GG] }

    it 'can show offenders needing early allocation decision updates' do
      stub_offender(offender_nos.first, booking_number: 754_205)
      stub_offender(offender_nos.last, booking_number: 754_204)

      offender_nos.each do |offender_no|
        create(:case_information, nomis_offender_id: offender_no, tier: 'A', mappa_level: 1)
        create(:allocation_version, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)
      end

      create(:early_allocation, :discretionary, :skip_validate, nomis_offender_id: offender_nos.first)
      create(:early_allocation, :stage2, :skip_validate, nomis_offender_id: offender_nos.last)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)
      expect(pomtasks.first.offender_number).to eq(offender_nos.first)
      expect(pomtasks.first.action_label).to eq('Early allocation decision')
    end
  end
end
