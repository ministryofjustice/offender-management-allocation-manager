require 'rails_helper'

RSpec.describe AllocationsController, type: :controller do
  let(:poms) {
    [
      {
        firstName: 'Alice',
        position: RecommendationService::PRISON_POM,
        staffId: 1
      },
      {
        firstName: 'Bob',
        position: RecommendationService::PRISON_POM,
        staffId: 2
      },
      {
        firstName: 'Clare',
        position: RecommendationService::PROBATION_POM,
        staffId: 3,
        emails: ['pom3@prison.gov.uk']
      },
      {
        firstName: 'Dave',
        position: RecommendationService::PROBATION_POM,
        staffId: 4,
        emails: ['pom4@prison.gov.uk']
      }
    ]
  }

  before do
    stub_sso_data(prison)

    stub_poms(prison, poms)
  end

  context 'when user is a POM' do
    let(:prison) { 'LEI' }
    let(:offender_no) { 'G7806VO' }

    before do
      stub_poms(prison, poms)
      stub_sso_pom_data(prison)
      stub_signed_in_pom(1, 'Alice')
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/").
        with(headers: { 'Authorization' => 'Bearer token' }).
        to_return(status: 200, body: { staffId: 1 }.to_json, headers: {})
    end

    it 'is not visible' do
      get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
      expect(response).to redirect_to('/')
    end
  end

  describe '#show' do
    let(:prison) { 'WEI' }

    context 'when POM has left' do
      let(:offender_no) { 'G7806VO' }
      let(:pom_staff_id) { 543_453 }
      let(:poms) {
        [{
          firstName: 'Alice',
          position: RecommendationService::PRISON_POM,
          staffId: 123
        }]
      }

      before do
        stub_offender(offender_no)
        stub_poms(prison, poms)

        create(:case_information, nomis_offender_id: offender_no)
        create(:allocation_version, nomis_offender_id: offender_no, primary_pom_nomis_id: pom_staff_id)

        stub_request(:get, "https://keyworker-api-dev.prison.service.justice.gov.uk/key-worker/WEI/offender/G7806VO").
          to_return(status: 200, body: { staffId: 123_456 }.to_json, headers: {})
      end

      it 'redirects to the inactive POM page' do
        get :show, params: { prison_id: prison, nomis_offender_id: offender_no }
        expect(response).to redirect_to(prison_pom_non_pom_path(prison, pom_staff_id))
      end
    end
  end

  describe '#history' do
    let(:prison) { 'AYI' }
    let(:offender_no) { 'G7806VO' }
    let(:pom_staff_id) { 1 }

    before do
      stub_offender(offender_no)
      create(:case_information, nomis_offender_id: offender_no)

      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/1").
        to_return(status: 200, body: {}.to_json, headers: {})

      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/PK000223").
        to_return(status: 200, body: { staffId: 3 }.to_json, headers: {})

      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/4").
        to_return(status: 200, body: {}.to_json, headers: {})

      stub_pom_emails(5, [])
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/5").
        to_return(status: 200, body: {}.to_json, headers: {})
    end

    context 'when DeliusDataJob updating the COM name', :versioning do
      let!(:d1) { create(:delius_data, offender_manager: 'Mr Todd', noms_no: offender_no) }
      let(:create_time) { 3.days.ago }
      let(:update_time) { 2.days.ago }

      before do
        x = create(:allocation_version, primary_pom_nomis_id: 1, allocated_at_tier: 'C', nomis_offender_id: d1.noms_no,
                                        created_at: create_time, updated_at: create_time)
        x.update(allocated_at_tier: 'D', updated_at: update_time)
        ProcessDeliusDataJob.perform_now offender_no
      end

      it 'doesnt mess up the allocation history' do
        get :history, params: { prison_id: prison, nomis_offender_id: d1.noms_no }
        allocation_list = assigns(:history).first.second
        expect(allocation_list.size).to eq(2)
        expect(allocation_list.map(&:updated_at)).to eq([update_time, create_time])
      end
    end

    context 'without DeliusDataJob' do
      before do
        allocation = create(:allocation_version,
                            nomis_offender_id: offender_no,
                            nomis_booking_id: 1,
                            primary_pom_nomis_id: 4,
                            allocated_at_tier: 'A',
                            prison: 'PVI',
                            recommended_pom_type: 'probation',
                            event: AllocationVersion::ALLOCATE_PRIMARY_POM,
                            event_trigger: AllocationVersion::USER,
                            created_by_username: 'PK000223'
        )
        allocation.update!(
          primary_pom_nomis_id: 5,
          prison: 'LEI',
          event: AllocationVersion::REALLOCATE_PRIMARY_POM,
          event_trigger: AllocationVersion::USER,
          created_by_username: 'PK000223'
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

      it "can get email addresses of POM's who have been allocated to an offender given the allocation history", versioning: true do
        previous_primary_pom_nomis_id = 3
        updated_primary_pom_nomis_id = 4
        primary_pom_without_email_id = 5

        allocation = create(
          :allocation_version,
          nomis_offender_id: offender_no,
          primary_pom_nomis_id: previous_primary_pom_nomis_id)

        allocation.update!(
          primary_pom_nomis_id: updated_primary_pom_nomis_id,
          event: AllocationVersion::REALLOCATE_PRIMARY_POM
        )

        allocation.update!(
          primary_pom_nomis_id: primary_pom_without_email_id,
          event: AllocationVersion::REALLOCATE_PRIMARY_POM
        )

        allocation.update!(
          primary_pom_nomis_id: updated_primary_pom_nomis_id,
          event: AllocationVersion::REALLOCATE_PRIMARY_POM
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
    let(:prison) { 'WSI' }

    let(:offender_no) { 'G7806VO' }

    before do
      stub_offender(offender_no)
    end

    context 'when tier A offender' do
      it 'serves recommended POMs' do
        create(:case_information, nomis_offender_id: offender_no, tier: 'A')

        get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

        expect(response).to be_successful

        expect(assigns(:recommended_poms).map(&:first_name)).to match_array(%w[Clare Dave])
      end
    end

    context 'when tier D offender' do
      it 'serves recommended POMs' do
        create(:case_information, nomis_offender_id: offender_no, tier: 'D')

        get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

        expect(response).to be_successful

        expect(assigns(:recommended_poms).map(&:first_name)).to match_array(%w[Alice Bob])
      end
    end
  end
end
