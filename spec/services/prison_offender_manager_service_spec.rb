require 'rails_helper'

describe PrisonOffenderManagerService do
  let(:other_staff_id) { 485_637 }
  let(:staff_id) { 485_737 }

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  describe '#get_pom_name' do
    it "can get staff names",
       vcr: { cassette_name: :pom_service_staff_name } do
      fname, lname = described_class.get_pom_name(staff_id)
      expect(fname).to eq('JAY')
      expect(lname).to eq('HEAL')
    end
  end

  describe '#get_user_name' do
    it "can get user names",
       vcr: { cassette_name: :pom_service_user_name } do
      fname, lname = described_class.get_user_name('RJONES')
      expect(fname).to eq('ROSS')
      expect(lname).to eq('JONES')
    end
  end

  describe '#get_allocated_offenders' do
    let(:old) { 8.days.ago }

    let(:old_primary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation_version,
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: 'G4273GI',
          nomis_booking_id: 1_153_753
        )
      end
    }

    let(:old_secondary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation_version,
          primary_pom_nomis_id: other_staff_id,
          nomis_offender_id: 'G8060UF',
          nomis_booking_id: 971_856
        ).tap { |item|
          item.update!(secondary_pom_nomis_id: staff_id)
        }
      end
    }

    let(:primary_alloc) {
      create(
        :allocation_version,
        primary_pom_nomis_id: staff_id,
        nomis_offender_id: 'G8624GK',
        nomis_booking_id: 76_908
      )
    }

    let(:secondary_alloc) {
      create(
        :allocation_version,
        primary_pom_nomis_id: other_staff_id,
        nomis_offender_id: 'G1714GU',
        nomis_booking_id: 31_777
      ).tap { |item|
        item.update!(secondary_pom_nomis_id: staff_id)
      }
    }

    let!(:all_allocations) {
      [old_primary_alloc, old_secondary_alloc, primary_alloc, secondary_alloc]
    }

    before do
      old_primary_alloc.update!(secondary_pom_nomis_id: other_staff_id)
    end

    it "will get allocations for a POM made within the last 7 days", :versioning, vcr: { cassette_name: :get_new_cases } do
      allocated_offenders = described_class.
        get_allocated_offenders(staff_id, 'LEI').
        select(&:new_case?)
      expect(allocated_offenders.count).to eq 2
      expect(allocated_offenders.map(&:responsibility)).to match_array [ResponsibilityService::SUPPORTING, 'Co-Working']
    end
  end

  describe '#get_poms' do
    it "can get a list of POMs",
       vcr: { cassette_name: :pom_service_get_poms_list } do
      poms = described_class.get_poms('LEI')
      expect(poms).to be_kind_of(Array)
      expect(poms.count).to eq(14)
    end

    it "can get a filtered list of POMs",
       vcr: { cassette_name: :pom_service_get_poms_filtered } do
      poms = described_class.get_poms('LEI').select { |pom|
        pom.status == 'active'
      }
      expect(poms).to be_kind_of(Array)
      expect(poms.count).to eq(13)
    end
  end

  describe '#get_pom_names' do
    it "can get the names for POMs when given IDs",
       vcr: { cassette_name: :pom_service_get_poms_by_ids } do
      names = described_class.get_pom_names('LEI')
      expect(names).to be_kind_of(Hash)
      expect(names.count).to eq(13)
    end
  end

  describe '#get_pom' do
    it "can fetch a single POM for a prison",
       vcr: { cassette_name: :pom_service_get_pom_ok } do
      pom = described_class.get_pom('LEI', staff_id)
      expect(pom).not_to be nil
    end

    it "can handle no poms for a prison when fetching a pom",
       vcr: { cassette_name: :pom_service_get_pom_none } do
      pom = described_class.get_pom('CFI', 1234)
      expect(pom).to be nil
    end

    context 'when pom not existing at a prison' do
      let(:t3) { 'https://gateway.t3.nomis-api.hmpps.dsd.io' }
      let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
      let(:access_token) { 'an access token' }

      before do
        allow(Nomis::Oauth::TokenService).to receive(:valid_token).and_return(OpenStruct.new(access_token: access_token))

        stub_request(:post, "#{t3}/auth/oauth/token?grant_type=client_credentials").
          to_return(status: 200, body: {
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": 1199,
            "scope": "readwrite"
          }.to_json, headers: {})
        stub_request(:get, "#{elite2api}/staff/roles/LEI/role/POM").
          with(
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Page-Limit' => '100',
              'Page-Offset' => '0'
            }).
          to_return(status: 200, body: [
            { "staffId": 485_833, "firstName": "FRED", "lastName": "BLOGGS", "status": "ACTIVE", "gender": "F",
              "dateOfBirth": "1980-01-01", "agencyId": "LEI", "agencyDescription": "Leeds (HMP)",
              "fromDate": "2019-05-31", "position": "PRO", "positionDescription": "Prison Officer",
              "role": "POM", "roleDescription": "Prison Offender Manager", "scheduleType": "FT",
              "scheduleTypeDescription": "Full Time", "hoursPerWeek": 35 },
            { "staffId": 485_846, "firstName": "JIM", "lastName": "STEINMAN", "status": "ACTIVE", "gender": "M",
              "dateOfBirth": "1980-01-01", "agencyId": "LEI", "agencyDescription": "Leeds (HMP)", "fromDate": "2019-07-01",
              "position": "PRO", "positionDescription": "Prison Officer", "role": "POM",
              "roleDescription": "Prison Offender Manager", "scheduleType": "FT", "scheduleTypeDescription": "Full Time",
              "hoursPerWeek": 35 }
          ].to_json, headers: {})
      end

      it "returns nil" do
        pom = described_class.get_pom('LEI', 1234)
        expect(pom).to be nil
      end
    end
  end
end
