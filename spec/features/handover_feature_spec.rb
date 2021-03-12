require "rails_helper"

feature "viewing upcoming handovers" do
  let(:prison) { 'LEI' }
  let(:user) { build(:pom) }

  context 'when signed in as an SPO' do
    let(:offender) { build(:nomis_offender, latestLocationId: prison) }
    let!(:case_info) { create(:case_information, nomis_offender_id: offender.fetch(:offenderNo)) }

    before do
      # Stub auth
      signin_spo_user
      stub_auth_token
      stub_user(staff_id: user.staff_id)

      # Stub an offender in the prison
      stub_offenders_for_prison(prison, [offender])

      # Stub handover dates for the offender
      allow_any_instance_of(HmppsApi::OffenderBase).to receive(:handover_start_date).and_return(handover_start_date)
      allow_any_instance_of(HmppsApi::OffenderBase).to receive(:responsibility_handover_date).and_return(responsibility_handover_date)

      visit prison_handovers_path(prison)
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

  context 'with four offenders' do
    let(:pom_names) { ["Dunlop, Abbey", "Brown, Denis", "Albright, Sally", "Carsley, Jo"] }
    let(:coms) { ["Dabery, Suzzie", "Canne, Sam", "Blackburn, Zoe", "Abbot, Brian"] }

    let(:check_poms) { ["Albright, Sally", "Brown, Denis", "Carsley, Jo", "Dunlop, Abbey"] }
    let(:check_coms) { ["Abbot, Brian", "Blackburn, Zoe", "Canne, Sam", "Dabery, Suzzie"] }
    let(:check_dates) { ["Abbot, Brian", "Canne, Sam", "Blackburn, Zoe", "Dabery, Suzzie"] }

    before do
      stub_auth_token
      stub_user(staff_id: user.staff_id)

      offenders = [
          build(:nomis_offender,
                offenderNo: "A7514GW",
                sentence: attributes_for(:sentence_detail, :handover_in_28_days)),
          build(:nomis_offender,
                offenderNo: "B7514GW",
                sentence: attributes_for(:sentence_detail, :handover_in_14_days)),
          build(:nomis_offender, offenderNo: "C7514GW",
                sentence: attributes_for(:sentence_detail, :handover_in_21_days)),
          build(:nomis_offender, offenderNo: "D7514GW",
                sentence: attributes_for(:sentence_detail, :handover_in_6_days))
      ]

      stub_offenders_for_prison(prison, offenders)

      offenders.each_with_index do |offender, i|
        create(:case_information,  com_name: coms.fetch(i),  nomis_offender_id: offender.fetch(:offenderNo))
        create(:allocation, primary_pom_nomis_id: user.staff_id, primary_pom_name: pom_names.fetch(i), nomis_offender_id: offender.fetch(:offenderNo), prison: prison)
      end
    end

    context 'without the SPO role' do
      before do
        signin_pom_user
        stub_poms(prison, [user])
      end

      it 'stops staff without the SPO role from viewing the SPO page' do
        visit prison_handovers_path(prison)
        expect(page).to have_current_path('/401')
      end

      it 'can load the POM handovers page', :js do
        visit prison_staff_caseload_handovers_path(prison, user.staff_id)
        click_link('Handover start date')
        check_dates.each_with_index do |name, index|
          expect(page).to have_css(".offender_row_#{index}", text: name)
        end

        click_link('Handover start date')
        check_dates.reverse.each_with_index do |name, index|
          expect(page).to have_css(".offender_row_#{index}", text: name)
        end

        click_link('Responsibility changes')
        check_dates.each_with_index do |name, index|
          expect(page).to have_css(".offender_row_#{index}", text: name)
        end

        click_link('Responsibility changes')
        check_dates.reverse.each_with_index do |name, index|
          expect(page).to have_css(".offender_row_#{index}", text: name)
        end
      end
    end

    context 'with the SPO role' do
      before do
        signin_spo_user
        visit prison_handovers_path(prison)
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
end
