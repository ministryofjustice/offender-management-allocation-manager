require 'rails_helper'

describe PrisonOffenderManagerService do
  let(:other_staff_id) { 485_637 }
  let(:staff_id) { 485_833 }

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  context 'when using T3 and VCR' do
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

    describe '#get_poms_for' do
      subject {
        described_class.get_poms_for('LEI')
      }

      let(:moic_integration_tests) { subject.detect { |x| x.first_name == 'MOIC' } }

      it "can get a list of POMs",
         vcr: { cassette_name: :pom_service_get_poms_list } do
        expect(subject).to be_kind_of(Enumerable)
        expect(subject.count).to eq(13)
        # 1 POM in T3 (Toby Retallick) is marked inactive, so expect one less active one
        expect(subject.select { |pom| pom.status == 'active' }.count).to eq(12)
        # would like these to both be true as integratopn test user has both positions
        # expect(moic_integration_tests.prison_officer?).to eq(true)
        expect(moic_integration_tests.probation_officer?).to eq(true)
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

    describe '#get_pom_at' do
      it "can fetch a single POM for a prison",
         vcr: { cassette_name: :pom_service_get_pom_ok } do
        pom = described_class.get_pom_at('LEI', staff_id)
        expect(pom).not_to be nil
      end

      it "raises an exception when fetching a pom if they are not a POM",
         vcr: { cassette_name: :pom_service_get_pom_none } do
        expect {
          described_class.get_pom_at('CFI', 1234)
        }.to raise_exception(StandardError)
      end
    end
  end

  context 'without T3 fixtures' do
    before do
      stub_auth_token
    end

    describe '#get_poms_for' do
      let(:alice) {
        {
          firstName: 'Alice',
          position: 'PO',
          staffId: 1,
          emails: ['test@digital.justice.org.uk']
        }
      }
      let(:billy) {
        {
          firstName: 'Billy',
          position: 'PRO',
          staffId: 2,
          emails: ['test@digital.justice.org.uk']
        }
      }
      let(:charles) {
        {
          firstName: 'Alison',
          position: 'PPO',
          staffId: 1,
          emails: ['test@digital.justice.org.uk']
        }
      }
      let(:dave) {
        {
          firstName: 'Billy Bob',
          position: 'AO',
          staffId: 2,
          emails: ['test@digital.justice.org.uk']
        }
      }
      let(:eric) {
        {
          firstName: 'Billy Bob Eric',
          position: 'PO',
          staffId: 2,
          emails: ['test@digital.justice.org.uk']
        }
      }

      let(:poms) { [dave, alice, billy, charles, eric] }

      before do
        stub_poms('WSI', poms)
      end

      it 'removes duplicate staff ids, keeping the valid position' do
        expect(described_class.get_poms_for('WSI').map(&:first_name)).to eq([alice, billy].map { |p| p[:firstName] })
      end
    end

    describe '#get_pom_at' do
      context 'when pom not existing at a prison' do
        let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }

        before do
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

        it "raises" do
          expect {
            described_class.get_pom_at('LEI', 1234)
          }.to raise_exception(StandardError)
        end
      end
    end
  end
end
