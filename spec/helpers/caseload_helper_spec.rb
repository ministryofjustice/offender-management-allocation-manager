require 'rails_helper'

RSpec.describe CaseloadHelper do
  describe 'when getting facet counts' do
    let(:prison) { 'LEI' }
    let(:staff_id) { 1 }
    let(:poms) { [{ firstName: 'Alice', position: 'PRO', staffId: staff_id }] }
    let(:offenders) {
      [
     { "latestBookingId": 754_207, "offenderNo": "G7514GW", "firstName": "Alice", "lastName": "Aliceson",
       "dateOfBirth": "1990-12-06", "age": 28, "agencyId": prison, "categoryCode": "C", "imprisonmentStatus": "LIFE" },
     { "latestBookingId": 754_206, "offenderNo": "G1234VV", "firstName": "Bob", "lastName": "Bibby",
       "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" },
     { "latestBookingId": 754_205, "offenderNo": "G1234AB", "firstName": "Carole", "lastName": "Caroleson",
       "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" },
     { "latestBookingId": 754_204, "offenderNo": "G1234GG", "firstName": "David", "lastName": "Davidson",
       "dateOfBirth": "2001-02-02", "age": 18, "agencyId": prison, "categoryCode": "D", "imprisonmentStatus": "SENT03" }
        ]
    }
    let(:bookings) {
      [
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
    }

    before do
      stub_poms(prison, poms)
      stub_signed_in_pom(staff_id, 'alice')
      stub_multiple_offenders(offenders, bookings)
    end

    it 'handles zero allocations' do
      facets = filter_facets([])

      CaseloadFilters.constants.map { |c| CaseloadFilters.const_get(c) }.each { |f|
        expect(facets[f]).to eq(0)
      }
    end

    it 'handles new allocations', versioning: true do
      offenders.each do |offender|
        create(:allocation_version, nomis_offender_id: offender[:offenderNo], primary_pom_nomis_id: staff_id, prison: prison, primary_pom_allocated_at: DateTime.now.utc)
      end

      caseload = PomCaseload.new(staff_id, prison)
      expect(caseload.allocations.count).to eq(4)

      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::NEW_ALLOCATION]).to eq(4)
      expect(facets[CaseloadFilters::OLD_ALLOCATION]).to eq(0)
    end

    it 'handles all old allocations', versioning: true do
      Timecop.travel(10.days.ago) do
        offenders.each{ |offender|
          create(:allocation_version, nomis_offender_id: offender[:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
        }
      end

      caseload = PomCaseload.new(staff_id, prison)
      expect(caseload.allocations.count).to eq(4)

      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::OLD_ALLOCATION]).to eq(4)
      expect(facets[CaseloadFilters::NEW_ALLOCATION]).to eq(0)
    end

    it 'new and old allocations cannot > total', versioning: true do
      offenders[0..1].each do |offender|
        create(:allocation_version, nomis_offender_id: offender[:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
      end

      Timecop.travel(10.days.ago) do
        offenders[2..3].each{ |offender|
          create(:allocation_version, nomis_offender_id: offender[:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
        }
      end

      caseload = PomCaseload.new(staff_id, prison)
      expect(caseload.allocations.count).to eq(4)

      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::OLD_ALLOCATION]).to eq(2)
      expect(facets[CaseloadFilters::NEW_ALLOCATION]).to eq(2)
    end

    it 'handover facets can be faceted' do
      offenders.each do |offender|
        create(:allocation_version, nomis_offender_id: offender[:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
      end

      caseload = PomCaseload.new(staff_id, prison)
      expect(caseload.allocations.count).to eq(4)

      allow(HandoverDateService).to receive(:handover_start_date).and_return([nil, ''])
      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::HANDOVER_UNKNOWN]).to eq(4)

      allow(HandoverDateService).to receive(:handover_start_date).and_return([Time.zone.today + 7.days, ''])
      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::HANDOVER_STARTS_SOON]).to eq(4)

      allow(HandoverDateService).to receive(:handover_start_date).and_return([Time.zone.today - 2.days, ''])
      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::HANDOVER_IN_PROGRESS]).to eq(4)
    end

    it 'responsibility facets can be faceted' do
      # 1 x Responsible
      create(:allocation_version, nomis_offender_id: offenders[0][:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
      # 2 x Supporting
      create(:allocation_version, nomis_offender_id: offenders[1][:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
      create(:allocation_version, nomis_offender_id: offenders[2][:offenderNo], primary_pom_nomis_id: staff_id, prison: prison)
      # 1 x Coworking
      create(:allocation_version, nomis_offender_id: offenders[3][:offenderNo], secondary_pom_nomis_id: staff_id, prison: prison)

      caseload = PomCaseload.new(staff_id, prison)
      expect(caseload.allocations.count).to eq(4)

      facets = filter_facets(caseload.allocations)
      expect(facets[CaseloadFilters::ROLE_RESPONSIBLE]).to eq(1)
      expect(facets[CaseloadFilters::ROLE_SUPPORTING]).to eq(2)
      expect(facets[CaseloadFilters::ROLE_COWORKING]).to eq(1)
    end
  end
end
