require "rails_helper"

feature "get poms list", flaky: true do
  let(:offender_missing_sentence_case_info) { create(:case_information, offender: build(:offender, nomis_offender_id: 'G1247VX')) }

  # NOMIS Staff ID of the POM called "Moic Pom"
  let(:moic_pom_id) { 485_926 }

  before do
    allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_return({})
    signin_spo_user
  end

  it "shows the page" do
    visit prison_poms_path('LEI')

    # shows 3 tabs - probation, prison and inactive
    expect(page).to have_css(".govuk-tabs__list-item", count: 3)
    expect(page).to have_content("Active probation officer POMs")
    expect(page).to have_content("Active prison officer POMs")
    expect(page).to have_content("Inactive staff")
  end

  # This example is a bit misleading. From what I can tell, this offender (G1247VX) _does_ have a valid sentence.
  # If they were missing the required sentence data, they shouldn't be available in the service.
  # Therefore, I'm not entirely sure what the intention is behind this test aside from showing that allocations are displayed on the POM's caseload.
  it "handles missing sentence data" do
    visit prison_prisoner_staff_index_path('LEI', offender_missing_sentence_case_info.nomis_offender_id)

    within '#recommended_poms' do
      within row_containing 'Moic Pom' do
        click_link 'Allocate'
      end
    end

    expect(page).to have_css('h1', text: "Check allocation details for Aianilan Albina")

    click_button 'Complete allocation'

    visit prison_pom_path('LEI', moic_pom_id)
    click_link 'Caseload'

    expect(page).to have_css("#all-cases .offender_row_0", count: 1)
    expect(page).not_to have_css("#all-cases .offender_row_1")
    expect(page).to have_content(offender_missing_sentence_case_info.nomis_offender_id)
  end

  it "allows viewing a POM", :js do
    visit prison_pom_path('LEI', moic_pom_id)

    expect(page).to have_content("Moic Pom")
    expect(page).to have_content("Caseload")

    # click through the 'Total cases' link and make sure we arrive
    expect(page).not_to have_content "Allocation date"
    first('.card__heading--large').click
    expect(page).to have_content "All cases (0)"
  end

  describe 'sorting' do
    before do
      ['G7806VO', 'G2911GD'].each do |offender_id|
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_id))
        create(:allocation_history, prison: 'LEI', nomis_offender_id: offender_id, primary_pom_nomis_id: moic_pom_id)
      end
    end

    it 'can sort' do
      visit "/prisons/LEI/poms/#{moic_pom_id}"

      expect(page).to have_content("Moic Pom")
      click_link 'Caseload'
      expect(page).to have_content("Caseload")
      expect(page).to have_css('#all-cases .sort-arrow', count: 1)

      check_for_order = lambda { |names|
        row0 = page.find(:css, '#all-cases .offender_row_0')
        row1 = page.find(:css, '#all-cases .offender_row_1')

        within row0 do
          expect(page).to have_content(names[0])
        end

        within row1 do
          expect(page).to have_content(names[1])
        end
      }

      check_for_order.call(['Abdoria, Ongmetain', 'Ahmonis, Imanjah'])
      find('#all-cases').click_link('Case')
      check_for_order.call(['Ahmonis, Imanjah', 'Abdoria, Ongmetain'])
    end

    describe 'sorting by role' do
      before do
        secondary = create :case_information, offender: build(:offender, nomis_offender_id: 'G4328GK')
        create(:allocation_history, prison: 'LEI', nomis_offender_id: secondary.nomis_offender_id,
                                    primary_pom_nomis_id: 123_456, secondary_pom_nomis_id: moic_pom_id)

        visit "/prisons/LEI/poms/#{moic_pom_id}"
        click_link 'Caseload'
      end

      it 'can sort' do
        find('#all-cases').click_link 'Role'
        expect(all('#all-cases td[aria-label=Role]').map(&:text).uniq).to eq(['Co-working', 'Supporting'])
        find('#all-cases').click_link 'Role'
        expect(all('#all-cases td[aria-label=Role]').map(&:text).uniq).to eq(['Supporting', 'Co-working'])
      end
    end
  end

  it "allows editing a POM" do
    visit "/prisons/LEI/poms/#{moic_pom_id}/edit"

    expect(page).to have_css(".govuk-button", count: 1)
    expect(page).to have_css(".govuk-radios__item", count: 14)
    expect(page).to have_content("Edit profile")
    expect(page).to have_content("Working pattern")
    expect(page).to have_content("Status")
  end
end
