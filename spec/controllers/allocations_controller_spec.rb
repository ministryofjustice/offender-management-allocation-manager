# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllocationsController, type: :controller do
  let(:poms) {
    [
      build(:pom, :prison_officer, emails: []),
      build(:pom, :prison_officer),
      build(:pom, :probation_officer),
      build(:pom, :probation_officer)
    ]
  }
  let(:pom_without_emails) { poms.first }
  let(:prison) { create(:prison).code }
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:offenderNo) }

  before do
    stub_poms(prison, poms)
    stub_offender(offender)
    stub_movements_for offender_no, [attributes_for(:movement)]
  end

  context 'when user is a POM' do
    let(:signed_in_pom) { poms.last }

    before do
      stub_signed_in_pom(prison, signed_in_pom.staffId, 'Alice')
    end

    it 'is not visible' do
      get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
      expect(response).to redirect_to('/401')
    end

    it 'allows access for anyone in the POMs caseload' do
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: poms.last.staffId)
      get :history, params: { prison_id: prison, nomis_offender_id: offender_no }
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when user is an SPO' do
    before do
      stub_sso_data(prison)
    end

    describe '#show' do
      let(:inactive_pom_staff_id) { 543_453 }

      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
        stub_keyworker(prison, offender_no, staffId: 123_456)
      end

      context 'when POM has left' do
        before do
          create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: inactive_pom_staff_id)
        end

        it 'redirects to the inactive POM page' do
          get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
          expect(response).to redirect_to(prison_pom_non_pom_path(prison, inactive_pom_staff_id))
        end
      end

      context 'with an inactive co-worker' do
        before do
          create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: poms.first.staffId, secondary_pom_nomis_id: inactive_pom_staff_id)
        end

        it 'shows the page' do
          get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe '#history' do
      let(:pom_staff_id) { 754732 }

      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      end

      context 'with a VictimLiasonOfficer' do
        before do
          case_info = create(:case_information, victim_liaison_officers: [build(:victim_liaison_officer)])
          create(:allocation_history, nomis_offender_id: case_info.nomis_offender_id)
          stub_offender(build(:nomis_offender, offenderNo: case_info.nomis_offender_id))
          stub_movements_for case_info.nomis_offender_id, [attributes_for(:movement)]
          stub_pom_emails(485926, [])
        end

        let(:case_info) { CaseInformation.last }
        let(:vlo_offender_no) { case_info.nomis_offender_id }
        let(:history) { assigns(:history) }
        let(:allocation) { AllocationHistory.find_by!(nomis_offender_id: vlo_offender_no) }

        it 'has a VLO create record' do
          get :history, params: { prison_id: prison, nomis_offender_id: vlo_offender_no }
          expect(history.map(&:event)).to eq(['create', 'allocate_primary_pom'])
        end

        context 'with update and delete VLO events' do
          before do
            case_info.victim_liaison_officers.first.update!(first_name: 'Bill', last_name: 'Smuggs')
            case_info.victim_liaison_officers.first.destroy
            allocation.update!(
              primary_pom_nomis_id: poms.second.staffId,
              event: AllocationHistory::REALLOCATE_PRIMARY_POM
            )
          end

          it 'has VLO and alloocation data sorted by date' do
            get :history, params: { prison_id: prison, nomis_offender_id: vlo_offender_no }
            expect(history.map(&:event)).to eq(['create', 'allocate_primary_pom', 'update', 'destroy', "reallocate_primary_pom"])
          end
        end
      end

      context 'when COM name has been updated by nDelius', :disable_push_to_delius do
        let(:create_time) { 3.days.ago }
        let(:create_date) { create_time.to_date }
        let(:yesterday) { 1.day.ago.to_date }

        before do
          stub_community_offender(offender_no, build(:community_data))
        end

        context 'when create, delius, update' do
          before do
            x = create(:allocation_history, primary_pom_nomis_id: poms.first.staffId, allocated_at_tier: 'C',
                       nomis_offender_id: offender_no,
                       created_at: create_time,
                       updated_at: create_time)
            Timecop.travel 2.days.ago do
              ProcessDeliusDataJob.perform_now offender_no
            end
            x.reload
            Timecop.travel 1.day.ago do
              x.update(allocated_at_tier: 'D')
            end
          end

          # This is now an impossible scenario due to moving the COM name to CaseInformation
          # but we need to keep this test for now as we might have historical broken data
          it 'doesnt mess up the allocation history updated_at because we surface the value' do
            get :history, params: { prison_id: prison, nomis_offender_id: offender_no }
            history = assigns(:history)
            expect(history.size).to eq(2)
            expect(history.map(&:created_at).map(&:to_date)).to eq([create_date, yesterday])
          end
        end

        context 'when delius is updated' do
          before do
            create(:allocation_history, primary_pom_nomis_id: 1, allocated_at_tier: 'C',
                   nomis_offender_id: offender_no,
                   created_at: create_time,
                   updated_at: create_time)
            Timecop.travel 2.days.ago do
              ProcessDeliusDataJob.perform_now offender_no
            end

            stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/key-worker/#{prison}/offender/#{offender_no}").
              to_return(body: { staffId: 123_456 }.to_json)
          end

          it 'shows the correct date on the show page' do
            get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
            alloc = assigns(:allocation)
            expect(alloc.created_at.to_date).to eq(create_date)
          end
        end
      end

      context 'without DeliusDataJob' do
        render_views

        context 'with an allocation' do
          before do
            allocation = create(:allocation_history,
                                nomis_offender_id: offender_no,
                                primary_pom_nomis_id: poms.first.staffId,
                                allocated_at_tier: 'A',
                                prison: 'PVI',
                                recommended_pom_type: 'probation',
                                event: AllocationHistory::ALLOCATE_PRIMARY_POM,
                                event_trigger: AllocationHistory::USER
            )
            allocation.update!(
              primary_pom_nomis_id: poms.second.staffId,
              prison: 'LEI',
              event: AllocationHistory::REALLOCATE_PRIMARY_POM,
              event_trigger: AllocationHistory::USER)
          end

          it "get the allocation history for an offender" do
            get :history, params: { prison_id: prison, nomis_offender_id: offender_no }
            allocation_list = assigns(:history)

            expect(allocation_list.map(&:event)).to eq(['allocate_primary_pom', 'allocate_primary_pom'])
          end
        end
      end
    end

    describe '#new' do
      context 'with previous allocations for this POM' do
        let(:alice) { poms.first }

        before do
          { a: 5, b: 4, c: 3, d: 2 }.each do |tier, quantity|
            0.upto(quantity - 1) do
              info = create(:case_information, tier: tier.to_s.upcase)
              create(:allocation_history, prison: prison, nomis_offender_id: info.nomis_offender_id, primary_pom_nomis_id: alice.staffId)
            end
          end
          info = create(:case_information, tier: 'N/A')
          create(:allocation_history, prison: prison, nomis_offender_id: info.nomis_offender_id, primary_pom_nomis_id: alice.staffId)

          offenders = CaseInformation.all.map { |ci| build(:nomis_offender, offenderNo: ci.nomis_offender_id) }
          stub_offenders_for_prison(prison, offenders, [attributes_for(:movement)])

          create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), tier: tier)
          get :index, params: { prison_id: prison, prisoner_id: offender_no }
          expect(response).to be_successful
        end

        context 'when tier D' do
          let(:tier) { 'D' }

          render_views

          it 'serves correct counts' do
            pom = assigns(:recommended_poms).detect { |c| c.first_name == alice.firstName }

            expect(tier_a: pom.allocations.count { |a| a.tier == 'A' },
                   tier_b: pom.allocations.count { |a| a.tier == 'B' },
                   tier_c: pom.allocations.count { |a| a.tier == 'C' },
                   tier_d: pom.allocations.count { |a| a.tier == 'D' },
                   no_tier: pom.allocations.count { |a| a.tier == 'N/A' },
                   total_cases: pom.allocations.count)
                .to eq(tier_a: 5, tier_b: 4, tier_c: 3, tier_d: 2, no_tier: 1, total_cases: 15)
          end

          it 'has a nil allocation' do
            expect(assigns(:allocation)).to be_nil
            expect(response.body).to have_content 'No history'
          end

          it 'serves recommended POMs' do
            expect(assigns(:recommended_poms).map(&:first_name)).to match_array(poms.first(2).map(&:firstName))
          end
        end

        context 'when tier A' do
          let(:tier) { 'A' }

          it 'serves recommended POMs' do
            expect(assigns(:recommended_poms).map(&:first_name)).to match_array(poms.last(2).map(&:firstName))
          end
        end
      end

      context 'with an allocation' do
        before do
          stub_offenders_for_prison(prison, [offender])
          create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
          create(:allocation_history, nomis_offender_id: offender_no)
        end

        before do
          get :index, params: { prison_id: prison, prisoner_id: offender_no }
          expect(response).to be_successful
        end

        it 'displays an allocation link' do
          expect(assigns(:allocation)).not_to be_nil
        end
      end
    end
  end
end
