require 'rails_helper'

describe PrisonOffenderManagerService do
  let(:other_staff_id) { 485_637 }
  let(:staff_id) { 485_833 }

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  describe '#get_pom_name' do
    it "can get staff names",
       vcr: { cassette_name: :pom_service_staff_name } do
      fname, lname = described_class.get_pom_name(staff_id)
      expect(fname).to eq('ANDRIEN')
      expect(lname).to eq('RICKETTS')
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
      let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }

      before do
        stub_auth_token

        stub_request(:get, "#{elite2api}/staff/roles/LEI/role/POM").
          with(
            headers: {
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
      let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }

      before do
        stub_auth_token

        stub_request(:get, "#{elite2api}/staff/roles/LEI/role/POM").
          with(
            headers: {
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
