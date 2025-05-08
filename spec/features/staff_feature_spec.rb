require "rails_helper"

feature "staff pages" do
  feature "POM page" do
    let(:prison) { create(:prison) }
    let(:pom) { build(:pom) }
    let(:prison_poms) { build_list(:pom, 8, :prison_officer, status: 'inactive') }
    let(:offender_count) { 6 }

    let(:offenders_in_prison) do
      build_list(:nomis_offender, offender_count,
                 prisonId: prison.code,
                 category: attributes_for(:offender_category),
                 sentence: attributes_for(:sentence_detail))
    end

    let(:offender_attrs) do
      {
        full_name: 'Surname1, Firstname1',
        last_name: 'Surname1',
        offender_no: 'X1111XX',
        tier: 'A',
        handover_progress_task_completion_data: {},
        allocated_com_email: nil,
        allocated_com_name: nil,
        ldu_name: nil,
        ldu_email_address: nil,
        handover_progress_complete?: false,
        case_information: double(enhanced_handover?: false),
        handover_type: 'enhanced',
        earliest_release_for_handover: { name: 'Bobbins', date: Time.zone.today + 100 }
      }
    end

    let(:offender) { sneaky_instance_double AllocatedOffender, **offender_attrs }

    before do
      stub_signin_spo pom, [prison.code]
      stub_offenders_for_prison(prison.code, offenders_in_prison)
      stub_poms(prison.code, prison_poms + [pom])

      offenders_in_prison.each do |offender|
        nomis_offender_id = offender[:prisonerNumber]

        offender = create(:offender, nomis_offender_id:)

        create(
          :allocation_history,
          :primary,
          prison: prison.code,
          nomis_offender_id: nomis_offender_id,
          primary_pom_nomis_id: pom.staff_id,
          recommended_pom_type: 'prison'
        )

        create(:case_information, offender:)

        create(:calculated_handover_date, offender:, handover_date: Time.zone.today + 5)
      end

      visit prison_pom_path(prison.code, pom.staff_id)
    end

    it "has a heading" do
      expect(page).to have_css('h2', text: 'Overview')
    end

    it "has 4 sub-navigation tab links" do
      expect(page).to have_css('.moj-sub-navigation a', text: 'Overview')
      expect(page).to have_css('.moj-sub-navigation a', text: 'Caseload')
      expect(page).to have_css('.moj-sub-navigation a', text: 'Handover cases')
      expect(page).to have_css('.moj-sub-navigation a', text: 'Parole')
    end

    it "has 3 caseload cards" do
      expect(page).to have_css('.card--caseload p', text: 'total cases')
      expect(page).to have_css('.card--caseload p', text: 'handovers in progress')
      expect(page).to have_css('.card--caseload p', text: 'parole cases')
    end

    describe "Caseload sub-navigation" do
      before do
        click_link 'Caseload'
      end

      it "has a heading" do
        expect(page).to have_css('h1', text: 'Caseload')
      end

      it "has 3 sub-navigation tab links" do
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'All cases')
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'Allocated in last 7 days')
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'Releases in next 4 weeks')
      end

      describe 'All cases sub-navigation' do
        # We're already on this tab
        it "has a heading" do
          expect(page).to have_css('h3', text: 'All cases')
        end

        it 'has a list of cases' do
          expect(page).to have_css('#all-cases .govuk-table__body .govuk-table__row', count: offender_count)
        end

        it 'can sort' do
          # To regression test a sorting bug Aug 2023
          find('#all-cases a', text: 'Role').click
        end
      end

      describe 'Allocated in last 7 days sub-navigation' do
        before { click_link 'Allocated in last 7 days' }

        it "has a heading" do
          expect(page).to have_css('h3', text: 'Allocated in last 7 days')
        end
      end

      describe 'Releases in next 4 weeks sub-navigation' do
        before { click_link 'Releases in next 4 weeks' }

        it "has a heading" do
          expect(page).to have_css('h3', text: 'Releases in next 4 weeks')
        end
      end
    end

    describe "Handover cases sub-navigation" do
      before do
        click_link 'Handover cases'
      end

      it "has a heading" do
        expect(page).to have_css('h1', text: 'Handover cases')
      end

      it "has 4 sub-navigation tab links" do
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'Upcoming handovers')
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'Handovers in progress')
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'Overdue tasks')
        expect(page).to have_css('.govuk-tabs__list-item a', text: 'COM allocation overdue')
      end

      describe 'Upcoming handovers tab' do
        # We're already on this tab
        it "has a heading" do
          expect(page).to have_css('h3', text: 'Upcoming handovers')
        end
      end

      describe 'Handovers in progress tab' do
        before do
          click_link 'Handovers in progress'
        end

        it "has a heading" do
          expect(page).to have_css('h3', text: 'Handovers in progress')
        end
      end

      describe 'Overdue tasks tab' do
        before do
          click_link 'Overdue tasks'
        end

        it "has a heading" do
          expect(page).to have_css('h3', text: 'Overdue tasks')
        end
      end

      describe 'COM allocation overdue tab' do
        before do
          click_link 'COM allocation overdue'
        end

        it "has a heading" do
          expect(page).to have_css('h3', text: 'COM allocation overdue')
        end
      end
    end

    describe "Parole sub-navigation" do
      before do
        click_link 'Parole'
      end

      it "has a heading" do
        expect(page).to have_css('p', text: 'All cases in this prison with a target hearing date, PED or TED in the next 10 months')
      end
    end
  end

  feature "female estate POMs list" do
    let!(:female_prison) { create(:womens_prison).code }
    let(:staff_id) { 123_456 }
    let(:spo) { build(:pom) }

    let(:probation_poms) do
      [
        # Need deterministic POM order by surname
        build(:pom, :probation_officer, lastName: 'Smith', firstName: 'Janine'),
        build(:pom, :probation_officer, lastName: 'Watkins', firstName: 'Janet')
      ]
    end

    let(:prison_poms) { build_list(:pom, 8, :prison_officer, status: 'inactive') }
    let(:poms) { probation_poms + prison_poms }

    let(:nomis_offender) do
      build(:nomis_offender,
            firstName: 'Novel',
            lastName: 'Offender',
            prisonId: female_prison, complexityLevel: 'high',
            category: attributes_for(:offender_category, :female_closed),
            sentence: attributes_for(:sentence_detail))
    end

    let(:offenders_in_prison) do
      build_list(:nomis_offender, 14,
                 prisonId: female_prison,
                 category: attributes_for(:offender_category, :female_closed),
                 sentence: attributes_for(:sentence_detail))
    end

    before do
      stub_signin_spo spo, [female_prison]
      stub_offenders_for_prison(female_prison, offenders_in_prison << nomis_offender)
      stub_poms(female_prison, poms)

      offenders_in_prison.map { |o| o.fetch(:prisonerNumber) }.each do |nomis_id|
        stub_keyworker female_prison, nomis_id, build(:keyworker)
      end

      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender[:prisonerNumber]), enhanced_resourcing: true)
      create(:allocation_history, nomis_offender_id: nomis_offender[:prisonerNumber], primary_pom_nomis_id: poms.first.staffId, prison: female_prison)

      %w[A B C].each_with_index do |tier, index|
        create(:case_information, tier: tier, offender: build(:offender, nomis_offender_id: offenders_in_prison[index][:prisonerNumber]), enhanced_resourcing: true)
        create(:allocation_history, nomis_offender_id: offenders_in_prison[index][:prisonerNumber], primary_pom_nomis_id: poms.first.staffId, prison: female_prison)
      end

      %w[D N/A].each_with_index do |tier, index|
        create(:case_information, tier: tier, offender: build(:offender, nomis_offender_id: offenders_in_prison[index + 4][:prisonerNumber]), enhanced_resourcing: true)
        create(:allocation_history, nomis_offender_id: offenders_in_prison[index + 4][:prisonerNumber], primary_pom_nomis_id: poms.last.staffId, prison: female_prison)
      end

      visit prison_poms_path(female_prison)
    end

    it 'shows the POM staff page' do
      expect(page).to have_content("Manage your staff")
      expect(page).to have_content("Active Probation officer POM")
      expect(page).to have_content("Active Prison officer POM")
      expect(page).to have_content("Inactive staff")
    end

    it "can display active probation POMs case mix" do
      pom_row = find('td', text: poms.first.full_name_ordered).ancestor('tr')

      within pom_row do
        within ".case-mix-bar" do
          expect(page).to have_css(".case-mix__tier_a", text: '2')
          expect(page).to have_css(".case-mix__tier_b", text: '1')
          expect(page).to have_css(".case-mix__tier_c", text: '1')
        end
        expect(page).to have_css('td[aria-label="High complexity cases"]', text: '1')
        expect(page).to have_css('td[aria-label="Total cases"]', text: '4')
      end
    end

    it 'can display active prison POMs case mix' do
      click_on('Active Prison officer POMs')

      pom_row = find('td', text: poms.last.full_name_ordered).ancestor('tr')

      within pom_row do
        within ".case-mix-bar" do
          expect(page).to have_css(".case-mix__tier_d", text: '1')
          expect(page).to have_css(".case-mix__tier_na", text: '1')
        end
        expect(page).to have_css('td[aria-label="High complexity cases"]', text: '0')
        expect(page).to have_css('td[aria-label="Total cases"]', text: '2')
      end
    end

    it 'displays the inactive POMs' do
      click_on('Inactive staff')

      expect(page).to have_content('POM')
      expect(page).to have_content('POM type')
      expect(page).to have_content('Total cases')
    end

    it 'can view a POM' do
      # click on the first POM
      within "#active_probation_poms" do
        click_link 'Janine Smith'
      end

      expect(page).to have_content('Working pattern')
      expect(page).to have_content('Status')

      click_link 'Caseload'

      within '#all-cases' do
        click_link 'Offender, Novel'
      end
    end
  end
end
