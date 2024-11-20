describe HandoversController do
  let(:prison) { double(code: 'DBG') }
  let(:default_params) { { prison_id: prison.code, pom: for_pom, sort: 'offender_last_name+asc' } }
  let(:staff_member) { double(staff_id: 456_987) }
  let(:handover_cases) do
    double :handover_cases, upcoming: double(:upcoming),
                            in_progress: double(:in_progress),
                            overdue_tasks: double(:overdue_tasks),
                            com_allocation_overdue: double(:com_allocation_overdue)
  end
  let(:for_pom) { 'user' }
  let(:current_user_is_pom) { double :current_user_is_pom }
  let(:current_user_is_spo) { double :current_user_is_spo }

  before do
    stub_high_level_staff_member_auth(prison:, staff_member:)

    allow(controller.helpers).to receive(:handover_cases_view).with(
      current_user: staff_member,
      prison:,
      current_user_is_pom:,
      current_user_is_spo:,
      for_pom:
    ).and_return(handover_cases)

    allow(controller).to receive_messages(
      current_user_is_pom?: current_user_is_pom,
      current_user_is_spo?: current_user_is_spo
    )

    allow(controller).to receive(:sort_and_paginate) { |arg| arg }
  end

  shared_examples 'handover cases list page' do |case_type|
    let(:with_sort) { true }
    let(:params) { with_sort ? default_params : default_params.except(:sort) }

    before do
      get case_type, params:
    end

    it 'renders successfully' do
      expect(response).to be_successful
    end

    it 'has prison id' do
      expect(assigns(:prison_id)).to eq prison.code
    end

    it 'sets current_handovers_url' do
      expect(flash[:current_handovers_url]).to eq request.url
    end

    it 'has handover cases list' do
      expect(assigns(:handover_cases)).to eq handover_cases
    end

    describe '@pom_view' do
      context 'when the user is an spo but for_pom params is empty' do
        let(:for_pom) { '' }
        let(:current_user_is_spo) { true }

        it 'is false' do
          expect(assigns[:pom_view]).to be(false)
        end
      end

      context 'when the user is an spo but for_pom params is user' do
        let(:for_pom) { 'user' }
        let(:current_user_is_spo) { true }

        it 'is true' do
          expect(assigns[:pom_view]).to be(true)
        end
      end

      context 'when the user is a pom' do
        let(:current_user_is_pom) { true }

        it 'is true' do
          expect(assigns[:pom_view]).to be(true)
        end
      end
    end

    it 'has correct paginated cases' do
      expect(assigns(:filtered_handover_cases)).to eq handover_cases.send(case_type)
    end

    context 'when no sorting specified' do
      let(:with_sort) { false }

      it 'defaults sort to handover_date+desc' do
        expected_path = send("#{case_type}_prison_handovers_path", default_params.merge(sort: 'handover_date asc'))
        expect(response).to redirect_to(expected_path)
      end
    end

    describe 'when user is not authorised' do
      let(:current_user_is_pom) { false }
      let(:current_user_is_spo) { false }

      it 'redirects to unauthorized' do
        get case_type, params: default_params
        expect(response).to redirect_to('/401')
      end
    end
  end

  it_behaves_like 'handover cases list page', :upcoming
  it_behaves_like 'handover cases list page', :in_progress
  it_behaves_like 'handover cases list page', :overdue_tasks
  it_behaves_like 'handover cases list page', :com_allocation_overdue
end
