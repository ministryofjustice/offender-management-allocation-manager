require 'rails_helper'

RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { create(:prison).code }
  let(:default_params) { { new_handover: NEW_HANDOVER_TOKEN, prison_id: prison_code } }

  let(:handover_case_listing) do
    instance_double HandoverCaseListingService, :handover_case_listing,
                    counts: double(:counts),
                    upcoming_handover_allocated_offenders: double(:upcoming_handover_allocated_offenders),
                    in_progress: double(:in_progress),
                    overdue_tasks: double(:overdue_tasks),
                    com_allocation_overdue: double(:com_allocation_overdue)
  end

  before do
    stub_sso_data(prison_code)

    allow(HandoverCaseListingService).to receive(:new).and_return(handover_case_listing)
  end

  describe 'index page' do
    it 'redirects to upcoming handovers' do
      get :index, params: default_params
      expect(response).to redirect_to(upcoming_prison_handovers_path(**default_params))
    end
  end

  describe 'upcoming handovers page' do
    before do
      get :upcoming, params: default_params
    end

    it 'renders successfully' do
      expect(response).to be_successful
    end

    it 'has counts' do
      expect(assigns(:counts)).to eq handover_case_listing.counts
    end

    it 'has list of upcoming handover cases' do
      expect(assigns(:upcoming_handover_allocated_offenders)).to eq handover_case_listing.upcoming_handover_allocated_offenders
    end
  end

  context 'when legacy page with 4 offenders' do
    let(:prison) { prison_code }
    let(:today_plus_10_days) { (Time.zone.today + 10.days).to_s }
    let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }

    before do
      offenders = [
        build(:nomis_offender,
              prisonerNumber: "G7514GW",
              imprisonmentStatus: "LR",
              lastName: 'SMITH',
              sentence: attributes_for(:sentence_detail, sentenceStartDate: "2011-01-20")),
        build(:nomis_offender, prisonerNumber: "G1234GY", imprisonmentStatus: "LIFE",
                               lastName: 'Minate-Offender',
                               sentence: attributes_for(:sentence_detail,
                                                        sentenceStartDate: "2009-02-08",
                                                        automaticReleaseDate: "2011-01-28")),
        build(:nomis_offender, prisonerNumber: "G1234VV",
                               lastName: 'JONES',
                               sentence: attributes_for(:sentence_detail,
                                                        sentenceStartDate: "2019-02-08",
                                                        automaticReleaseDate: today_plus_13_weeks)),
        build(:nomis_offender, prisonerNumber: "G4234GG",
                               imprisonmentStatus: "SENT03",
                               firstName: "Fourth", lastName: "Offender",
                               sentence: attributes_for(:sentence_detail,
                                                        automaticReleaseDate: today_plus_10_days,
                                                        homeDetentionCurfewActualDate: today_plus_10_days,
                                                        sentenceStartDate: "2019-02-08",
                                                       ))
      ]
      create(:case_information, case_allocation: 'NPS', offender: build(:offender, nomis_offender_id: 'G4234GG'))

      stub_offenders_for_prison(prison, offenders)
    end

    describe '#index' do
      before do
        stub_movements
      end

      describe 'with sorting' do
        before do
          create(:case_information, :with_com, case_allocation: 'CRC', offender: build(:offender, nomis_offender_id: 'G1234VV'))
          create(:allocation_history, prison: prison, nomis_offender_id: 'G1234VV', primary_pom_nomis_id: pom.staffId)
          stub_pom(pom)

          get :index, params: { prison_id: prison, sort: sort }
          expect(response).to be_successful
        end

        let(:pom) { build(:pom) }

        context 'when sorting by COM' do
          let(:sort) { 'allocated_com_name asc' }

          it 'sorts' do
            expect(assigns(:offenders).map(&:offender_no)).to eq(["G4234GG", 'G1234VV'])
          end
        end

        context 'when sorting by POM' do
          let(:sort) { 'allocated_pom_name desc' }

          it 'sorts' do
            expect(assigns(:offenders).map(&:offender_no)).to eq(['G1234VV', "G4234GG"])
          end
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
          create(:case_information, case_allocation: 'CRC', offender: build(:offender, nomis_offender_id: 'G1234VV'))
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
