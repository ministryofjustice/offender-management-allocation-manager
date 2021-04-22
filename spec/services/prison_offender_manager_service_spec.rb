# frozen_string_literal: true

require 'rails_helper'

describe PrisonOffenderManagerService do
  let(:other_staff_id) { 485_637 }
  let(:staff_id) { 485758 }

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  context 'when using T3 and VCR' do
    describe '#get_poms_for' do
      subject {
        described_class.get_poms_for('LEI')
      }

      let(:moic_integration_tests) { subject.detect { |x| x.first_name == 'MOIC' } }

      it "can get a list of POMs", vcr: { cassette_name: 'prison_api/pom_service_get_poms_list' } do
        expect(subject).to be_kind_of(Enumerable)
        expect(subject.count { |pom| pom.status == 'active' }).to eq(subject.count)
        expect(moic_integration_tests.probation_officer?).to eq(true)
      end
    end

    describe '#get_pom_at' do
      it "can fetch a single POM for a prison",
         vcr: { cassette_name: 'prison_api/pom_service_get_pom_ok' } do
        pom = described_class.get_pom_at('LEI', staff_id)
        expect(pom).not_to be nil
      end

      it "raises an exception when fetching a pom if they are not a POM",
         vcr: { cassette_name: 'prison_api/pom_service_get_pom_none' } do
        expect {
          described_class.get_pom_at('CFI', 1234)
        }.to raise_exception(StandardError)
      end
    end

    describe 'fetch_pom_name', vcr: { cassette_name: 'prison_api/pom_helper_fetch_pom_name' } do
      it 'fetches the POM name from NOMIS' do
        expect(described_class.fetch_pom_name(485_926)).to eq('POM, MOIC')
      end
    end
  end

  context 'without T3 fixtures' do
    before do
      stub_auth_token
    end

    describe '#get_poms_for' do
      let(:alice) {
        build(:pom,
              firstName: 'Alice',
              position: 'PO',
              staffId: 1,
              emails: ['test@digital.justice.org.uk']
        )
      }
      let(:billy) {
        build(:pom,
              firstName: 'Billy',
              position: 'PRO',
              staffId: 2,
              emails: ['test@digital.justice.org.uk']
        )
      }
      let(:charles) {
        build(:pom,
              firstName: 'Alison',
              position: 'PPO',
              staffId: 1,
              emails: ['test@digital.justice.org.uk']
        )
      }
      let(:dave) {
        build(:pom,
              firstName: 'Billy Bob',
              position: 'AO',
              staffId: 2,
              emails: ['test@digital.justice.org.uk']
        )
      }
      let(:eric) {
        build(:pom,
              firstName: 'Billy Bob Eric',
              position: 'PO',
              staffId: 2,
              emails: ['test@digital.justice.org.uk']
        )
      }
      let(:offender) { build(:nomis_offender) }

      before do
        stub_poms('WSI', [dave, alice, billy, charles, eric])
        stub_offenders_for_prison('WSI', [offender])
        stub_pom(alice)
        stub_pom(billy)
      end

      it 'removes duplicate staff ids, keeping the valid position' do
        expect(described_class.get_poms_for('WSI').map(&:first_name)).to eq([alice, billy].map(&:firstName))
      end
    end

    describe '#get_pom_at' do
      context 'when pom not existing at a prison' do
        before do
          stub_auth_token
          stub_offenders_for_prison('LEI', [build(:nomis_offender)])
          stub_request(:get, "#{ApiHelper::T3}/staff/roles/LEI/role/POM").
            with(
              headers: {
                'Page-Limit' => '100',
                'Page-Offset' => '0'
              }).
            to_return(body: [
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
            ].to_json)
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
