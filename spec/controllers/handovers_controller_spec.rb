require 'rails_helper'

RSpec.describe HandoversController, type: :controller do
  let(:prison) { build(:prison).code }

  before { stub_sso_data(prison) }

  context 'with 4 offenders' do
    let(:today_plus_10_days) { (Time.zone.today + 10.days).to_s }
    let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }

    before do
      offenders = [
          build(:nomis_offender,
                offenderNo: "G7514GW",
                imprisonmentStatus: "LR",
                lastName: 'SMITH',
                sentence: attributes_for(:sentence_detail, sentenceStartDate: "2011-01-20")),
          build(:nomis_offender, offenderNo: "G1234GY", imprisonmentStatus: "LIFE",
                lastName: 'Minate-Offender',
                sentence: attributes_for(:sentence_detail,
                                         sentenceStartDate: "2009-02-08",
                                         automaticReleaseDate: "2011-01-28")),
          build(:nomis_offender, offenderNo: "G1234VV",
                lastName: 'JONES',
                sentence: attributes_for(:sentence_detail,
                                         sentenceStartDate: "2019-02-08",
                                         automaticReleaseDate: today_plus_13_weeks)),
          build(:nomis_offender, offenderNo: "G4234GG",
                imprisonmentStatus: "SENT03",
                firstName: "Fourth", lastName: "Offender",
                sentence: attributes_for(:sentence_detail,
                                         automaticReleaseDate: today_plus_10_days,
                                         homeDetentionCurfewActualDate: today_plus_10_days,
                                         sentenceStartDate: "2019-02-08",
                                         ))
      ]
      create(:case_information, case_allocation: 'NPS', nomis_offender_id: 'G4234GG')

      stub_offenders_for_prison(prison, offenders)
    end

    describe '#index' do
      before do
        stub_movements
      end

      describe 'sorting', :allocation do
        before do
          create(:case_information, :with_com, case_allocation: 'CRC', nomis_offender_id: 'G1234VV')
          create(:allocation, nomis_offender_id: 'G1234VV', primary_pom_nomis_id: pom.staffId)
          stub_pom(pom)
        end

        let(:pom) { build(:pom) }

        it 'sorts by COM' do
          get :index, params: { prison_id: prison, sort: 'allocated_com_name asc' }
          expect(response).to be_successful
          expect(assigns(:offenders).map(&:offender_no)).to eq(["G4234GG", 'G1234VV'])
        end

        it 'sorts by POM' do
          get :index, params: { prison_id: prison, sort: 'allocated_pom_name asc' }
          expect(response).to be_successful
          expect(assigns(:offenders).map(&:offender_no)).to eq(['G1234VV', "G4234GG"])
        end
      end

      context 'when NPS case' do
        it 'returns cases that are within the thirty day window, but not those that dont have case information' do
          get :index, params: { prison_id: prison }
          expect(response).to be_successful
          expect(assigns(:offenders).map(&:offender_no)).to match_array(["G4234GG"])
        end
      end

      context 'when CRC case' do
        before do
          create(:case_information, case_allocation: 'CRC', nomis_offender_id: 'G1234VV')
        end

        it 'returns cases that are within the thirty day window' do
          get :index, params: { prison_id: prison }
          expect(response).to be_successful
          expect(assigns(:offenders).map(&:offender_no)).to match_array(['G4234GG', "G1234VV"])
        end
      end
    end
  end
end
