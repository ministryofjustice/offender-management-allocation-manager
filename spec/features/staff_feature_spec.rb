require "rails_helper"

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

    create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender[:prisonerNumber]), case_allocation: 'NPS')
    create(:allocation_history, nomis_offender_id: nomis_offender[:prisonerNumber], primary_pom_nomis_id: poms.first.staffId, prison: female_prison)

    %w[A B C].each_with_index do |tier, index|
      create(:case_information, tier: tier, offender: build(:offender, nomis_offender_id: offenders_in_prison[index][:prisonerNumber]), case_allocation: 'NPS')
      create(:allocation_history, nomis_offender_id: offenders_in_prison[index][:prisonerNumber], primary_pom_nomis_id: poms.first.staffId, prison: female_prison)
    end

    %w[D N/A].each_with_index do |tier, index|
      create(:case_information, tier: tier, offender: build(:offender, nomis_offender_id: offenders_in_prison[index + 4][:prisonerNumber]), case_allocation: 'NPS')
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
