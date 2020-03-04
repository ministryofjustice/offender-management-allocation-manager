require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:staff_id) { 123 }
  let(:username) { 'alice' }
  let(:pom) {
    [
      build(:pom,
            staffId: staff_id,
            position: RecommendationService::PRISON_POM
      )
    ]
  }
  let(:next_week) { Time.zone.today + 7.days }

  before do
    stub_sso_pom_data(prison, username)

    stub_poms(prison, pom)
    stub_signed_in_pom(staff_id, username)

    offenders = [
      { "bookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Alice", "lastName": "Aliceson",
        "dateOfBirth": "1990-12-06", "age": 28, "categoryCode": "C", "imprisonmentStatus": "LIFE",
        "convictedStatus": "Convicted", "latestLocationId": prison },
      { "bookingId": 754_206, "offenderNo": "G1234VV", "firstName": "Bob", "lastName": "Bibby",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03",
        "convictedStatus": "Convicted", "latestLocationId": prison },
      { "bookingId": 754_205, "offenderNo": "G1234AB", "firstName": "Carole", "lastName": "Caroleson",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03",
        "convictedStatus": "Convicted", "latestLocationId": prison },
      { "bookingId": 754_204, "offenderNo": "G1234GG", "firstName": "David", "lastName": "Davidson",
        "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03",
        "convictedStatus": "Convicted", "latestLocationId": prison }
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

    # Allocate all of the offenders to this POM
    offenders.each do |offender|
      create(:allocation, nomis_offender_id: offender[:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
    end

    stub_offenders_for_prison(prison, offenders, bookings)
  end

  context 'when showing parole review date pom tasks' do
    let(:offender_no) { 'G7514GW' }

    it 'can show offenders needing parole review date updates' do
      stub_offender(offender_no, booking_number: 754_207, imprisonment_status: 'LIFE')

      # Make sure that we don't generate missing nDelius data by mistake
      create(:case_information, nomis_offender_id: offender_no, tier: 'A')
      create(:case_information, nomis_offender_id: 'G1234VV', tier: 'A', mappa_level: 1)
      create(:case_information, nomis_offender_id: 'G1234AB', tier: 'A', mappa_level: 1)
      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', mappa_level: 1)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)

      # We expect only one of these to have a parole review date task
      expect(pomtasks.first.offender_number).to eq(offender_no)
      expect(pomtasks.first.action_label).to eq('Parole review date')
    end
  end

  context 'when showing ndelius update pom tasks' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }
    let(:offender_no) { 'G1234VV' }

    before do
      test_strategy.switch!(:auto_delius_import, true)
    end

    after do
      test_strategy.switch!(:auto_delius_import, false)
    end

    it 'can show offenders needing nDelius updates' do
      stub_offender(offender_no, booking_number: 754_206)

      # Manual creation of case information cannot have a nil team, so create on here
      ldu = LocalDivisionalUnit.create!(code: "ENLDU", name: "English LDU", email_address: "EnglishNPS@example.com")
      team = Team.create!(code: "ENG1", name: 'NPS - England', shadow_code: "E01", local_divisional_unit_id: ldu.id)

      # Ensure only one of our offenders has missing data and that G7514GW (indeterminate) has a PRD
      create(:case_information, nomis_offender_id: offender_no, tier: 'A', team: team)
      create(:case_information, nomis_offender_id: 'G1234AB', tier: 'A', mappa_level: 1)
      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', mappa_level: 1)
      create(:case_information, nomis_offender_id: 'G7514GW', tier: 'A', mappa_level: 1, parole_review_date: next_week)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)
      expect(pomtasks.first.offender_number).to eq(offender_no)
      expect(pomtasks.first.action_label).to eq('nDelius case matching')
    end
  end

  context 'when showing early allocation decisions required' do
    let(:offender_nos) { %w[G1234AB G1234GG G7514GW G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    it 'can show offenders needing early allocation decision updates' do
      offender_nos.each do |offender_no|
        create(:case_information, nomis_offender_id: offender_no, tier: 'A', mappa_level: 1, parole_review_date: next_week)
      end

      create(:early_allocation, :discretionary, :skip_validate, nomis_offender_id: test_offender_no)
      create(:early_allocation, :stage2, :skip_validate, nomis_offender_id: test_offender_no)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)
      expect(pomtasks.first.offender_number).to eq(test_offender_no)
      expect(pomtasks.first.action_label).to eq('Early allocation decision')
    end
  end

  context 'when showing tasks' do
    let(:offender_nos) { %w[G1234AB G1234GG G7514GW G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    it 'can show multiple types at once' do
      # One offender (G1234VV) should have missing case info and one should have no PRD
      create(:case_information, nomis_offender_id: 'G1234AB', tier: 'A', mappa_level: 1, parole_review_date: next_week)
      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', mappa_level: 1, parole_review_date: next_week)
      create(:case_information, nomis_offender_id: 'G7514GW', tier: 'A', mappa_level: 1)

      # One offender should have a pending early allocation
      create(:early_allocation, :discretionary, :skip_validate, nomis_offender_id: test_offender_no)
      create(:early_allocation, :stage2, :skip_validate, nomis_offender_id: test_offender_no)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(2)
    end

    it 'can sort the results' do
      # One offender (G1234VV) should have missing case info and one should have no PRD
      create(:case_information, nomis_offender_id: 'G1234AB', tier: 'A', mappa_level: 1, parole_review_date: next_week)
      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', mappa_level: 1, parole_review_date: next_week)
      create(:case_information, nomis_offender_id: 'G7514GW', tier: 'A', mappa_level: 1)

      # Two offenders should have a pending early allocation
      create(:early_allocation, :discretionary, :skip_validate, nomis_offender_id: 'G1234AB')
      create(:early_allocation, :stage2, :skip_validate, nomis_offender_id: 'G1234AB')

      create(:early_allocation, :discretionary, :skip_validate, nomis_offender_id: 'G1234GG')
      create(:early_allocation, :stage2, :skip_validate, nomis_offender_id: 'G1234GG')

      get :index, params: { prison_id: prison, sort: 'offender_name asc' }
      expect(response).to be_successful
      pomtasks = assigns(:pomtasks)
      expect(pomtasks[0].offender_name).to eq('Aliceson, Alice')
      expect(pomtasks[2].offender_name).to eq('Davidson, David')

      get :index, params: { prison_id: prison, sort: 'offender_name desc' }
      expect(response).to be_successful
      pomtasks = assigns(:pomtasks)
      expect(pomtasks[0].offender_name).to eq('Davidson, David')
      expect(pomtasks[2].offender_name).to eq('Aliceson, Alice')
    end
  end
end
