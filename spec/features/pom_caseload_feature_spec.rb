require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_926 }
  let(:nomis_offender_id) { 'G4273GI' }
  let(:tomorrow) { Date.tomorrow }

  let(:prison) { 'LEI' }

  let(:offender_map) {
    {
      'G7266VD' => 1_073_602,
      'G8563UA' => 1_020_605,
      'G6068GV' => 1_030_841,
      'G0572VU' => 861_029,
      'G8668GF' => 1_106_348,
      'G9465UP' => 1_186_259,
      'G9372GQ' => 752_833,
      'G1618UI' => 1_161_236,
      'G4328GK' => 1_055_341,
      'G4143VX' => 1_083_858,
      'G8180UO' => 1_172_076,
      'G8909GV' => 877_782,
      'G8339GD' => 260_708,
      'G1992GH' => 1_179_167,
      'G1986GG' => 1_165_890,
      'G6262GI' => 961_997,
      'G6653UC' => 1_009_990,
      'G5992GA' => 928_042,
      'G4706UP' => 1_180_800,
      'G9344UG' => 841_994
    }
  }
  let(:offenders) {
    offender_map.merge(nomis_offender_id => 1_153_753).
      map { |nomis_id, booking_id|
      build(:nomis_offender,
            offenderNo: nomis_id,
            sentence: build(:nomis_sentence_detail,
                            tariffDate: Time.zone.today + booking_id.minutes))
    }
  }
  let(:sorted_offenders) {
    offenders.sort_by { |o| o.fetch(:lastName) }
  }
  let(:first_offender) { sorted_offenders.first }
  let(:moved_offender) { sorted_offenders.fourth }

  # create 21 allocations for prisoners named A-K so that we can verify that default sorted paging works
  before do
    poms =
      [
        build(:pom,
              firstName: 'Alice',
              position: RecommendationService::PRISON_POM,
              staffId: nomis_staff_id
        )
      ]

    stub_poms(prison, poms)
    stub_offenders_for_prison(prison, offenders)

    offender_map.each do |nomis_offender_id, nomis_booking_id|
      create(:case_information, nomis_offender_id: nomis_offender_id)
      create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id, nomis_booking_id: nomis_booking_id)
    end
    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', welsh_offender: 'Yes')
    create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id, nomis_booking_id: 1_153_753)

    offenders.last(15).each do |o|
      create(:responsibility, nomis_offender_id: o.fetch(:offenderNo), value: Responsibility::PROBATION)
    end

    allow_any_instance_of(Nomis::OffenderBase).to receive(:handover_start_date).and_return(tomorrow)
  end

  context 'when paginating' do
    before do
      signin_pom_user

      visit prison_staff_caseload_index_path('LEI', nomis_staff_id)
    end

    it 'displays paginated cases for a specific POM' do
      expect(page).to have_content("Showing 1 - 21 of 21 results")
      expect(page).to have_content("Your caseload (21)")
      sorted_offenders.first(20).each_with_index do |offender, index|
        name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"

        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be reverse sorted by name' do
      click_link 'Prisoner name'
      sorted_offenders.last(20).reverse.each_with_index do |offender, index|
        name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"
        within ".offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be sorted by earliest release date' do
      page.all('th')[2].find('a').click

      bookings_by_release_date = offenders.sort_by { |o| o.fetch(:sentence).fetch(:tariffDate) }
      [6, 7].each do |row_index|
        within ".offender_row_#{row_index}" do
          offender = offenders.detect { |o| o.fetch(:offenderNo) == bookings_by_release_date[row_index].fetch(:offenderNo) }
          name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be searched by string' do
      # make sure of at least one search hit.
      search = first_offender.fetch(:lastName)[1..4]
      expected_count = offenders.count { |o| o.fetch(:lastName).include?(search) || o.fetch(:firstName).include?(search) }
      fill_in 'q', with: search
      click_on 'Search'
      expect(page).to have_content("Showing 1 - #{expected_count} of #{expected_count} results")
    end

    it 'can be searched by number' do
      fill_in 'q', with: '8180U'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 1 of 1 results')
      offender = offenders.detect { |o| o.fetch(:offenderNo) == 'G8180UO' }
      name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"
      within '.offender_row_0' do
        expect(page).to have_content(name)
      end
    end

    it 'can be searched by supporting role' do
      select 'Supporting', from: 'role'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 15 of 15 results')
    end

    it 'shows the tier' do
      within('.offender_row_20 .tier') do
        expect(page).to have_content('A')
      end
    end

    it 'can be searched by responsible role' do
      select 'Responsible', from: 'role'
      click_on 'Search'
      expect(page).to have_content('Showing 1 - 6 of 6 results')
    end
  end

  context 'when looking at handover start' do
    before {
      signin_pom_user
      visit prison_staff_caseload_index_path('LEI', nomis_staff_id)
    }

    it 'shows the number of upcoming handovers' do
      within('.upcoming-handover-count') do
        expect(find('a').text).to eq('21')
      end
    end

    it 'can show us all upcoming handovers' do
      within('.upcoming-handover-count') do
        click_link('21')
      end

      expect(page).to have_css('tbody tr.govuk-table__row', count: 21)
    end
  end

  it 'allows a POM to view the prisoner profile page for a specific offender' do
    signin_pom_user
    stub_offender(first_offender)
    stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/key-worker/LEI/offender/#{first_offender.fetch(:offenderNo)}").
      to_return(body: { staffId: 485_572, firstName: "DOM", lastName: "BULL" }.to_json)
    visit prison_staff_caseload_index_path(prison, nomis_staff_id)

    expected_name = "#{first_offender.fetch(:lastName)}, #{first_offender.fetch(:firstName)}"

    within('.offender_row_0') do
      expect(page).to have_content(expected_name)
      click_link 'View'
    end

    expect(page).to have_current_path(prison_prisoner_path(prison, first_offender.fetch(:offenderNo)), ignore_query: true)
  end

  it 'can sort all cases that have been allocated to a specific POM in the last week', :versioning do
    # Sign in as a POM
    signin_pom_user
    visit  prison_staff_caseload_index_path('LEI', nomis_staff_id)
    within('.new-cases-count') do
      click_link('1')
    end

    expect(page).to have_content("New cases")

    expected_name = "#{first_offender.fetch(:lastName)}, #{first_offender.fetch(:firstName)}"

    # The first name...
    within('.offender_row_0') do
      expect(find('.prisoner-name').text).to eq(expected_name)
    end

    # After sorting ...
    click_link('Prisoner name')

    # Should be the last name
    within('.offender_row_20') do
      expect(find('.prisoner-name').text).to eq(expected_name)
    end
  end
end
