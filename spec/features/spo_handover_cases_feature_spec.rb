require "rails_helper"

feature "SPO viewing upcoming handover cases" do
  let(:prison) { 'LEI' }

  context 'when signed in as an SPO', vcr: { cassette_name: :spo_handover_cases_feature } do
    before do
      allow_any_instance_of(Nomis::OffenderBase).to receive_messages(
        handover_start_date: handover_start_date,
        responsibility_handover_date: responsibility_handover_date
      )
      signin_spo_user
      visit prison_summary_handovers_path(prison)
    end

    context 'with handovers that start within the next thirty days' do
      let(:handover_start_date) { 15.days.from_now }
      let(:responsibility_handover_date) { 4.months.from_now }

      it 'displays them on the page' do
        expect(page).to have_selector('.offender_row_0')
      end
    end

    context "with handovers that start in more than 30 days' time" do
      let(:handover_start_date) { 31.days.from_now }
      let(:responsibility_handover_date) { 4.months.from_now }

      it 'does not display them on the page' do
        expect(page).not_to have_selector('.offender_row_0')
      end
    end

    context 'with handovers that have already started, but have not yet completed' do
      let(:handover_start_date) { 15.days.ago }
      let(:responsibility_handover_date) { 3.months.from_now }

      it 'displays them on the page' do
        expect(page).to have_selector('.offender_row_0')
      end
    end

    context 'with handovers that have already completed' do
      let(:handover_start_date) { 4.months.ago }
      let(:responsibility_handover_date) { 15.days.ago }

      it 'does not display them on the page' do
        expect(page).not_to have_selector('.offender_row_0')
      end
    end
  end

  it 'stops staff without the SPO role from viewing the page'  do
    signin_pom_user
    visit prison_summary_handovers_path(prison)
    expect(page).to have_current_path('/401')
  end
end
