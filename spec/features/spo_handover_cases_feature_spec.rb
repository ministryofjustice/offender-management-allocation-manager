require "rails_helper"

feature "SPO viewing upcoming handover cases" do
  let(:prison) { 'LEI' }

  context 'when signed in as an SPO' do
    let(:offender) { build(:nomis_offender, latestLocationId: prison) }
    let!(:case_info) { create(:case_information, nomis_offender_id: offender.fetch(:offenderNo)) }
    let(:handover_dates) {
      HandoverDateService::HandoverData.new(
        handover_start_date,
        responsibility_handover_date,
        'Stubbed handover date'
      )
    }

    before do
      # Stub auth
      signin_spo_user
      stub_auth_token
      stub_user(staff_id: 100)

      # Stub an offender in the prison
      stub_offenders_for_prison(prison, [offender])

      # Stub handover dates for the offender
      allow(HandoverDateService).to receive(:handover).and_return(handover_dates)

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

  it 'stops staff without the SPO role from viewing the page', vcr: { cassette_name: :spo_handover_cases_pom } do
    signin_pom_user
    visit prison_summary_handovers_path(prison)
    expect(page).to have_current_path('/401')
  end

  context 'with four offenders' do
    let(:poms) { ["Dunlop, Abbey", "Brown, Denis", "Albright, Sally", "Carsley, Jo"] }
    let(:coms) { ["Dabery, Suzzie", "Canne, Sam", "Blackburn, Zoe", "Abbot, Brian"] }

    let(:check_poms) { ["Albright, Sally", "Brown, Denis", "Carsley, Jo", "Dunlop, Abbey"] }
    let(:check_coms) { ["Abbot, Brian", "Blackburn, Zoe", "Canne, Sam", "Dabery, Suzzie"] }

    before do
      stub_auth_token
      stub_user(staff_id: 123_456)

      offenders = [
          build(:nomis_offender,
                offenderNo: "A7514GW",
                sentence: attributes_for(:sentence_detail, :inside_handover_window)),
          build(:nomis_offender,
                offenderNo: "B7514GW",
                sentence: attributes_for(:sentence_detail, :inside_handover_window)),
          build(:nomis_offender, offenderNo: "C7514GW",
                sentence: attributes_for(:sentence_detail, :inside_handover_window)),
          build(:nomis_offender, offenderNo: "D7514GW",
                sentence: attributes_for(:sentence_detail, :inside_handover_window))
      ]

      stub_offenders_for_prison(prison, offenders)

      offenders.each_with_index do |offender, i|
        create(:case_information,  com_name: coms.fetch(i),  nomis_offender_id: offender.fetch(:offenderNo))
        create(:allocation, primary_pom_name: poms.fetch(i), nomis_offender_id: offender.fetch(:offenderNo), prison: prison)
      end

      signin_spo_user
      visit prison_summary_handovers_path(prison)
    end

    scenario 'sorts POMs alphabetically' do
      click_link('POM')

      check_poms.each_with_index do |name, index|
        expect(page).to have_css(".offender_row_#{index}", text: name)
      end

      click_link('POM')
      check_poms.reverse.each_with_index do |name, index|
        expect(page).to have_css(".offender_row_#{index}", text: name)
      end
    end

    scenario 'sorts COMs alphabetically' do
      click_link('COM')

      check_coms.each_with_index do |name, index|
        expect(page).to have_css(".offender_row_#{index}", text: name)
      end

      click_link('COM')

      check_coms.reverse.each_with_index do |name, index|
        expect(page).to have_css(".offender_row_#{index}", text: name)
      end
    end
  end
end
