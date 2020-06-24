require 'rails_helper'

RSpec.describe AllocationsController, :versioning, type: :controller do
  let(:poms) {
    [
      build(:pom,
            :prison_officer,
            staffId: 1
      ),
      build(:pom,
            :prison_officer,
            staffId: 2
        ),
      build(:pom,
            :probation_officer,
            staffId: 3,
            emails: ['pom3@prison.gov.uk']
        ),
      build(:pom,
            :probation_officer,
            staffId: 4,
            emails: ['pom4@prison.gov.uk']
        )
    ]
  }
  let(:prison) { build(:prison).code }
  let(:offender_no) { build(:offender).offender_no }

  before do
    stub_poms(prison, poms)
  end

  context 'when user is a POM rather than an SPO' do
    before do
      stub_poms(prison, poms)
      stub_signed_in_pom(prison, 1, 'Alice')
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/").
        to_return(body: { staffId: 1 }.to_json)
    end

    it 'is not visible' do
      get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
      expect(response).to redirect_to('/401')
    end
  end

  context 'when user in SPO' do
    before do
      stub_sso_data(prison, 'alice')
      stub_offender(offender_no)
    end

    describe '#show' do
      let(:inactive_pom_staff_id) { 543_453 }

      before do
        create(:case_information, nomis_offender_id: offender_no)
        stub_request(:get, "https://keyworker-api-dev.prison.service.justice.gov.uk/key-worker/#{prison}/offender/#{offender_no}").
          to_return(body: { staffId: 123_456 }.to_json)
      end

      context 'when POM has left' do
        before do
          create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: inactive_pom_staff_id)
        end

        it 'redirects to the inactive POM page' do
          get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
          expect(response).to redirect_to(prison_pom_non_pom_path(prison, inactive_pom_staff_id))
        end
      end

      context 'with an inactive co-worker' do
        before do
          create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: 1, secondary_pom_nomis_id: inactive_pom_staff_id)
        end

        it 'shows the page' do
          get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe '#history' do
      let(:pom_staff_id) { 1 }

      before do
        create(:case_information, nomis_offender_id: offender_no)

        stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/1").
          to_return(status: 200, body: {}.to_json, headers: {})

        stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/MOIC_POM").
          to_return(status: 200, body: { staffId: 3 }.to_json, headers: {})

        stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/4").
          to_return(status: 200, body: {}.to_json, headers: {})

        stub_pom_emails(5, [])
        stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/5").
          to_return(status: 200, body: {}.to_json, headers: {})
      end

      context 'when DeliusDataJob has updated the COM name' do
        # set DOB to 8 stars so that Delius matching ignores DoB
        let!(:d1) { create(:delius_data, date_of_birth: '*' * 8, offender_manager: 'Mr Todd', noms_no: offender_no) }
        let(:create_time) { 3.days.ago }
        let(:create_date) { create_time.to_date }
        let(:yesterday) { 1.day.ago.to_date }

        context 'when create, delius, update' do
          before do
            x = create(:allocation, primary_pom_nomis_id: 1, allocated_at_tier: 'C',
                       nomis_offender_id: d1.noms_no,
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

          it 'doesnt mess up the allocation history updated_at as we surface the value' do
            get :history, params: { prison_id: prison, nomis_offender_id: d1.noms_no }
            history = assigns(:history)
            # one set of history as only 1 prison involved
            expect(history.size).to eq(1)
            # history is array of pairs - [prison, allocations]
            expect(history.first.size).to eq(2)
            expect(history.first.first).to eq 'LEI'

            allocation_list = history.first.second
            expect(allocation_list.size).to eq(2)
            expect(allocation_list.map(&:updated_at).map(&:to_date)).to eq([yesterday, create_date])
          end
        end

        context 'when delius updated' do
          before do
            create(:allocation, primary_pom_nomis_id: 1, allocated_at_tier: 'C',
                   nomis_offender_id: d1.noms_no,
                   created_at: create_time,
                   updated_at: create_time)
            Timecop.travel 2.days.ago do
              ProcessDeliusDataJob.perform_now offender_no
            end

            stub_request(:get, "https://keyworker-api-dev.prison.service.justice.gov.uk/key-worker/#{prison}/offender/#{offender_no}").
              to_return(body: { staffId: 123_456 }.to_json)
          end

          it 'shows the correct date on the show page' do
            get :show, params: { prison_id: prison, nomis_offender_id: d1.noms_no }
            alloc = assigns(:allocation)
            expect(alloc.updated_at.to_date).to eq(create_date)
          end
        end
      end

      context 'without DeliusDataJob' do
        render_views

        context 'with an allocation' do
          before do
            allocation = create(:allocation,
                                nomis_offender_id: offender_no,
                                nomis_booking_id: 1,
                                primary_pom_nomis_id: 4,
                                allocated_at_tier: 'A',
                                prison: 'PVI',
                                recommended_pom_type: 'probation',
                                event: Allocation::ALLOCATE_PRIMARY_POM,
                                event_trigger: Allocation::USER,
                                created_by_username: 'MOIC_POM'
            )
            allocation.update!(
              primary_pom_nomis_id: 5,
              prison: 'LEI',
              event: Allocation::REALLOCATE_PRIMARY_POM,
              event_trigger: Allocation::USER,
              created_by_username: 'MOIC_POM'
            )
          end

          it "Can get the allocation history for an offender", versioning: true do
            get :history, params: { prison_id: prison, nomis_offender_id: offender_no }
            allocation_list = assigns(:history).to_a

            expect(allocation_list.count).to eq(2)
            # We get back a list of prison, allocation_array pairs
            expect(allocation_list.map(&:size)).to eq([2, 2])
            # Prisons are 1 each - LEI then PVI
            expect(allocation_list.first.first).to eq('LEI')
            expect(allocation_list.last.first).to eq('PVI')

            # we have 2 1-element arrays
            arrays = allocation_list.map { |al| al.second.first }
            expect(arrays.size).to eq(2)

            expect(arrays.first.nomis_offender_id).to eq(offender_no)
            # expect to see reallocate event before allocate as the history is reversed
            expect(arrays.first.event).to eq('reallocate_primary_pom')
            expect(arrays.last.nomis_booking_id).to eq(1)
          end
        end
      end

      context 'with a different allocation' do
        it "can get email addresses of POM's who have been allocated to an offender given the allocation history", versioning: true do
          previous_primary_pom_nomis_id = 3
          updated_primary_pom_nomis_id = 4
          primary_pom_without_email_id = 5

          allocation = create(
            :allocation,
            nomis_offender_id: offender_no,
            prison: prison,
            override_reasons: ['other'],
            primary_pom_nomis_id: previous_primary_pom_nomis_id)

          allocation.update!(
            primary_pom_nomis_id: updated_primary_pom_nomis_id,
            event: Allocation::REALLOCATE_PRIMARY_POM
          )

          allocation.update!(
            primary_pom_nomis_id: primary_pom_without_email_id,
            event: Allocation::REALLOCATE_PRIMARY_POM
          )

          allocation.update!(
            primary_pom_nomis_id: updated_primary_pom_nomis_id,
            event: Allocation::REALLOCATE_PRIMARY_POM
          )

          get :history, params: { prison_id: prison, nomis_offender_id: offender_no }
          pom_emails = assigns(:pom_emails)

          expect(pom_emails.count).to eq(3)
          expect(pom_emails[primary_pom_without_email_id]).to eq(nil)
          expect(pom_emails[updated_primary_pom_nomis_id]).to eq('pom4@prison.gov.uk')
          expect(pom_emails[previous_primary_pom_nomis_id]).to eq('pom3@prison.gov.uk')
        end
      end
    end

    describe '#new' do
      let(:offender) { attributes_for(:offender, offenderNo: offender_no) }
      let(:booking) { attributes_for(:booking, bookingId: offender.fetch(:bookingId)) }

      before do
        stub_offenders_for_prison(prison, [offender], [booking])
      end

      context 'when tier A offender' do
        it 'serves recommended POMs' do
          create(:case_information, nomis_offender_id: offender_no, tier: 'A')

          get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

          expect(response).to be_successful

          expect(assigns(:recommended_poms).map(&:first_name)).to match_array(poms.last(2).map(&:firstName))
        end
      end

      context 'when tier D offender' do
        it 'serves recommended POMs' do
          create(:case_information, nomis_offender_id: offender_no, tier: 'D')

          get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

          expect(response).to be_successful

          expect(assigns(:recommended_poms).map(&:first_name)).to match_array(poms.first(2).map(&:firstName))
        end
      end
    end
  end
end
