require 'rails_helper'

RSpec.describe ParoleCasesController, type: :controller do
  let(:prison) { create(:prison).code }

  before { stub_sso_data(prison) }

  context 'with 5 offenders' do
    let(:today_plus_11_months) { (Time.zone.today + 11.months).to_s }
    let(:today_plus_9_months) { (Time.zone.today + 9.months).to_s }
    let(:today_plus_7_months) { (Time.zone.today + 7.months).to_s }
    let(:pom) { build(:pom, firstName: 'ANTHONY', lastName: 'ANDERSON') }
    let(:pom2) { build(:pom, firstName: 'BENEDICT', lastName: 'BRIDGERTON') }
    let(:pom3) { build(:pom, firstName: 'COLIN', lastName: 'COLVILLE') }

    before do
      offenders = [
        build(:nomis_offender,
              prisonerNumber: "G1234QQ",
              firstName: 'STEVEN',
              lastName: 'STEVENS',
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: "2020-04-19")),
        build(:nomis_offender,
              prisonerNumber: "G7514GW",
              firstName: 'STAN',
              lastName: 'SMITH',
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: "2011-01-20",
                                       paroleEligibilityDate: today_plus_9_months)),
        build(:nomis_offender,
              prisonerNumber: "G1234GY",
              imprisonmentStatus: "LIFE",
              firstName: 'Peter',
              lastName: 'PETERS',
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: "2009-02-08",
                                       paroleEligibilityDate: today_plus_11_months)),
        build(:nomis_offender,
              prisonerNumber: "G1234VV",
              firstName: 'JOE',
              lastName: 'JONES',
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: "2019-02-08",
                                       tariffDate: today_plus_7_months)),
        build(:nomis_offender,
              prisonerNumber: "G4234GG",
              imprisonmentStatus: "SENT03",
              firstName: 'PHILLIP',
              lastName: 'PHILLIPS',
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: "2019-02-08",
                                       tariffDate: today_plus_11_months)),
      ]

      create(:case_information,
             offender: build(:offender,
                             nomis_offender_id: 'G1234QQ',
                             responsibility: build(:responsibility, value: Responsibility::PRISON),
                             parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 7.months)]))

      # No allocation history - this offender should not appear in the list

      create(:case_information, :with_com,
             offender: build(:offender,
                             nomis_offender_id: 'G7514GW',
                             responsibility: build(:responsibility, value: Responsibility::PRISON),
                             parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 8.months)]))

      create(:allocation_history, prison: prison, nomis_offender_id: 'G7514GW', primary_pom_nomis_id: pom2.staffId)

      create(:case_information,
             offender: build(:offender,
                             nomis_offender_id: 'G1234GY',
                             responsibility: build(:responsibility, value: Responsibility::PRISON),
                             parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 1.year)]))

      create(:allocation_history, prison: prison, nomis_offender_id: 'G1234GY', primary_pom_nomis_id: pom2.staffId)

      create(:case_information, :with_com,
             offender: build(:offender,
                             nomis_offender_id: 'G1234VV',
                             responsibility: build(:responsibility, value: Responsibility::PROBATION),
                             parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 9.months)]))

      create(:allocation_history, prison: prison, nomis_offender_id: 'G1234VV', primary_pom_nomis_id: pom3.staffId)

      create(:case_information,
             offender: build(:offender,
                             nomis_offender_id: 'G4234GG',
                             responsibility: build(:responsibility, value: Responsibility::PRISON),
                             parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 1.year)]))

      create(:allocation_history, prison: prison, nomis_offender_id: 'G4234GG', primary_pom_nomis_id: pom3.staffId)

      stub_offenders_for_prison(prison, offenders)
    end

    describe '#index' do
      before do
        stub_const('USE_PPUD_PAROLE_DATA', true)
        stub_movements
      end

      it 'responds to a get request' do
        get :index, params: { prison_id: prison }
        expect(response).to be_successful
      end

      # includes the default search on offender last name
      it 'returns the relevant offenders' do
        get :index, params: { prison_id: prison }
        expect(assigns(:offenders).map(&:offender_no)).to eq(['G1234VV', 'G7514GW'])
      end

      describe 'with sorting' do
        context 'when sorting by offender' do
          it 'sorts' do
            get :index, params: { prison_id: prison, sort: 'last_name asc' }
            expect(assigns(:offenders).map(&:offender_no)).to eq(['G1234VV', 'G7514GW'])
          end
        end

        context 'when sorting by pom role' do
          it 'sorts' do
            get :index, params: { prison_id: prison, sort: 'pom_responsible? asc' }
            expect(assigns(:offenders).map(&:offender_no)).to eq(["G1234VV", "G7514GW"])
          end
        end

        context 'when sorting by next parole date' do
          it 'sorts' do
            get :index, params: { prison_id: prison, sort: 'next_parole_date desc' }
            expect(assigns(:offenders).map(&:offender_no)).to eq(["G1234VV", "G7514GW"])
          end
        end
      end
    end
  end
end
