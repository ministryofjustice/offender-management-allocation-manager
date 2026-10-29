require 'rails_helper'

RSpec.describe AllocationRetentionsController, type: :controller do
  include_context 'with HMPPS audit event capture'

  let(:prison) { create(:prison) }
  let(:offender_no) { 'A1234BC' }
  let(:offender) do
    instance_double(MpcOffender, offender_no:, full_name_ordered: 'Smith, John',
                                 recommended_pom_type: RecommendationService::PROBATION_POM)
  end
  let(:allocation) { build(:allocation_history, prison: prison.code, nomis_offender_id: offender_no) }
  let(:review) { instance_double(SignificantChanges, allocation:, any?: true) }
  let(:request_params) { { prison_id: prison.code, prisoner_id: offender_no } }

  before do
    stub_sso_data(prison.code)
    allow_any_instance_of(Prison).to receive(:allocated).and_return([offender])
    allow_any_instance_of(Prison).to receive(:allocations).and_return([allocation])
    allow(SignificantChanges).to receive(:for).and_return([review])
    allow(StaffMember).to receive(:new).and_return(instance_double(StaffMember, full_name_ordered: 'Jones, Jane'))
    allow(AllocationService).to receive(:retain)
  end

  it 'opens a fresh override form' do
    get :new, params: request_params

    expect(response).to be_successful
    expect(assigns(:override)).to be_a(OverrideForm)
    expect(assigns(:override).override_reasons).to be_empty
    expect(hmpps_audit_events).to have_recorded_event('VIEW_NEW_ALLOCATION_RETENTION_FORM', who: 'user', subject_type: 'PRISONER_ID', subject_id: offender_no)
  end

  it 'loads the allocated POM when evaluating real significant changes' do
    allow(offender).to receive(:offender).and_return(build(:offender, nomis_offender_id: offender_no))
    allocation.primary_pom_allocated_at = 2.days.ago
    pom = instance_double(PomWrapper, staff_id: allocation.primary_pom_nomis_id, position: RecommendationService::PRISON_POM)
    allow_any_instance_of(Prison).to receive(:get_list_of_poms).with(include_deleted: true).and_return([pom])
    allow(SignificantChanges).to receive(:for).and_call_original
    PaperTrail::Version.create!(
      item_type: 'CaseInformation', item_id: 1, event: 'update', nomis_offender_id: offender_no,
      created_at: 1.day.ago, object_changes: YAML.dump('tier' => %w[B A])
    )

    get :new, params: request_params

    expect(response).to be_successful
    expect(assigns(:override)).to be_a(OverrideForm)
  end

  it 'requires reasons and does not save an invalid submission' do
    post :create, params: request_params.merge(override_form: { override_reasons: [''] })

    expect(response).to have_http_status(:unprocessable_entity)
    expect(assigns(:override).errors[:override_reasons]).to be_present
    expect(AllocationService).not_to have_received(:retain)
  end

  it 'requires extra detail for other reasons' do
    post :create, params: request_params.merge(override_form: { override_reasons: ['other'] })

    expect(response).to have_http_status(:unprocessable_entity)
    expect(AllocationService).not_to have_received(:retain)
  end

  it 'saves valid reasons and returns to review allocations' do
    post :create, params: request_params.merge(
      override_form: { override_reasons: ['other'], more_detail: 'Keep the existing relationship' }
    )

    expect(AllocationService).to have_received(:retain).with(
      allocation:,
      override: have_attributes(override_reasons: ['other'], more_detail: 'Keep the existing relationship'),
      recommended_pom_type: RecommendationService::PROBATION_POM
    )
    expect(response).to redirect_to(review_allocations_prison_prisoners_path(prison))
    expect(flash[:notice]).to eq('Smith, John still allocated to Jones, Jane')
  end

  [:new, :create].each do |action|
    it "rejects a case outside the prison's allocated cases on #{action}" do
      allow_any_instance_of(Prison).to receive(:allocated).and_return([])
      process action, method: action == :new ? :get : :post, params: request_params

      expect(response).to redirect_to('/404')
      expect(AllocationService).not_to have_received(:retain)
    end

    it "requires outstanding significant changes on #{action}" do
      allow(review).to receive(:any?).and_return(false)
      process action, method: action == :new ? :get : :post, params: request_params

      expect(response).to redirect_to(review_allocations_prison_prisoners_path(prison))
      expect(AllocationService).not_to have_received(:retain)
    end

    it "requires SPO permissions on #{action}" do
      allow(controller).to receive(:current_user_is_spo?).and_return(false)
      process action, method: action == :new ? :get : :post, params: request_params

      expect(response).to redirect_to('/401')
      expect(AllocationService).not_to have_received(:retain)
    end
  end
end
