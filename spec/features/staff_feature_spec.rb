require "rails_helper"

feature "staff pages" do
  feature "POM page" do
    let(:prison) { create(:prison) }
    let(:pom) { build(:pom) }
    let(:prison_poms) { build_list(:pom, 8, :prison_officer, status: 'inactive') }

    let(:offenders_in_prison) do
      build_list(:nomis_offender, 14,
                 prisonId: prison.code,
                 category: attributes_for(:offender_category),
                 sentence: attributes_for(:sentence_detail))
    end

    before do
      stub_signin_spo pom, [prison.code]
      stub_offenders_for_prison(prison.code, offenders_in_prison)
      stub_poms(prison.code, prison_poms)

      # FIXME: A stub_ helper probably negates the need for this
      stub_request(:get, "https://api-dev.prison.service.justice.gov.uk/api/staff/0")
         .with(
           headers: {
             'Authorization' => 'Bearer an-access-token',
             'Expect' => '',
             'User-Agent' => 'Faraday v1.10.3'
           })
         .to_return(status: 200, body: "{}", headers: {})

      visit prison_pom_path(prison.code, pom)
    end

    it "has a heading" do
      expect(page).to have_css('h1', text: 'Overview')
    end

    it "has 3 sub-navigation tab links" do
      expect(page).to have_css('.moj-sub-navigation a', text: 'Overview')
      expect(page).to have_css('.moj-sub-navigation a', text: 'Caseload')
      expect(page).to have_css('.moj-sub-navigation a', text: 'Handover cases')
    end

    it "has 2 caseload cards" do
      expect(page).to have_css('.card--caseload p', text: 'total cases')
      expect(page).to have_css('.card--caseload p', text: 'handovers in progress')
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
  end

  feature "female estate POMs list" do
    let!(:female_prison) { create(:womens_prison).code }
    let(:staff_id) { 123_456 }
    let(:spo) { build(:pom) }

    let(:probation_poms) do
      [
        # Need deterministic POM order by surname
        build(:pom, :probation_officer, lastName: 'Smith'),
        build(:pom, :probation_officer, lastName: 'Watkins')
      ]
    end

    let(:prison_poms) { build_list(:pom, 8, :prison_officer, status: 'inactive') }
    let(:poms) { probation_poms + prison_poms }

    let(:nomis_offender) do
      build(:nomis_offender,
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
        first('td.govuk-table__cell > a').click
      end

      expect(page).to have_content('Working pattern')
      expect(page).to have_content('Status')

      click_link 'Caseload'
      # click on first prisoner name
      first('.govuk-table a:nth-child(1)').click
    end
  end
end
