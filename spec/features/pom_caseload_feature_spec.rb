# frozen_string_literal: true

require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_926 }
  let(:nomis_offender_id) { 'G4273GI' }
  let(:tomorrow) { Date.tomorrow }

  let(:offender_map) {
    {
      'G7266VD' => 1_073,
      'G8563UA' => 1_020,
      'G6068GV' => 1_030,
      'G0572VU' => 861,
      'G8668GF' => 1_106,
      'G9465UP' => 1_186,
      'G9372GQ' => 752,
      'G1618UI' => 1_161,
      'G4328GK' => 1_055,
      'G4143VX' => 1_083,
      'G8180UO' => 1_172,
      'G8909GV' => 877,
      'G8339GD' => 260,
      'G1992GH' => 1_179,
      'G1986GG' => 1_165,
      'G6262GI' => 961,
      'G6653UC' => 1_009,
      'G5992GA' => 928,
      'G4706UP' => 1_180,
      'G9344UG' => 841
    }
  }
  let(:nil_release_date_offender) { 'G9372GQ' }
  let(:offender_ids_by_release_date) {
    offender_map.excluding(nil_release_date_offender).map { |k, v| [k, v] }.sort_by { |_k, v| v }.map { |k, _v| k }
  }
  let(:offenders) {
    ids_without_cells = %w(G6653UC G8563UA)
    offender_map.merge(nomis_offender_id => 1_153).
      map { |nomis_id, booking_id|
      if ids_without_cells.include? nomis_id
        # generate 2 offenders without a cell location
        build(:nomis_offender, internalLocation: nil,
              offenderNo: nomis_id,
              sentence: attributes_for(:sentence_detail,
                                       automaticReleaseDate: "2031-01-22",
                                       conditionalReleaseDate: "2031-01-24",
                                       tariffDate: (nomis_id == nil_release_date_offender) ? nil : Time.zone.today + booking_id.days))
      else
        build(:nomis_offender,
              offenderNo: nomis_id,
              sentence: attributes_for(:sentence_detail,
                                       automaticReleaseDate: "2031-01-22",
                                       conditionalReleaseDate: "2031-01-24",
                                       tariffDate: (nomis_id == nil_release_date_offender) ? nil : Time.zone.today + booking_id.days))
      end
    }
  }
  let(:missing_cells) {
    offenders.find_all { |x| x[:internalLocation] == nil }
  }
  let(:sorted_offenders) {
    offenders.sort_by { |o| o.fetch(:lastName) }
  }
  let(:first_offender) { sorted_offenders.first }
  let(:moved_offenders) { [sorted_offenders.fourth, sorted_offenders.fifth] }

  let(:sorted_locations) do
    removed_list = [moved_offenders.first, moved_offenders.last, missing_cells.first, missing_cells.last]
    offenders.reject { |x| removed_list.include? x }.sort_by { |o| o.fetch(:internalLocation) }
  end

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

    stub_auth_token
    stub_poms(prison.code, poms)
    signin_pom_user [prison.code]
    stub_offenders_for_prison(prison.code, offenders, [
      attributes_for(:movement, :rotl, offenderNo: moved_offenders.first.fetch(:offenderNo)),
      attributes_for(:movement, :rotl, offenderNo: moved_offenders.last.fetch(:offenderNo))
    ])

    offender_map.each do |nomis_offender_id, _nomis_booking_id|
      create(:case_information, nomis_offender_id: nomis_offender_id)
      create(:allocation, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id)
    end
    create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPS', probation_service: 'Wales')
    create(:allocation, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id)

    offenders.last(15).each do |o|
      create(:responsibility, nomis_offender_id: o.fetch(:offenderNo), value: Responsibility::PROBATION)
    end

    allow_any_instance_of(HmppsApi::OffenderBase).to receive(:handover_start_date).and_return(tomorrow)

    stub_user staff_id: nomis_staff_id
  end

  context 'when in a womens prison' do
    let(:prison) { build(:womens_prison) }
    let(:complexities) { ['high', 'medium', 'low'].cycle.take(offenders.size) }

    before do
      offenders.each_with_index do |offender, index|
        allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender.fetch(:offenderNo)).and_return(complexities[index])
      end
      visit prison_staff_caseload_path(prison.code, nomis_staff_id)
    end

    it 'can sort by complexity' do
      click_link 'Complexity level'
      expect(page).to have_current_path("/prisons/#{prison.code}/staff/#{nomis_staff_id}/caseload?sort=complexity_level_number+asc")
      click_link 'Complexity level'
      expect(page).to have_current_path("/prisons/#{prison.code}/staff/#{nomis_staff_id}/caseload?sort=complexity_level_number+desc")
    end
  end

  context 'when in a mens prison' do
    let(:prison) { build(:prison) }

    before do
      visit prison_staff_caseload_path(prison.code, nomis_staff_id)
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
      page.all('th')[3].find('a').click

      # pick out a few rows, and make sure they are in order by release date
      (2..7).each do |row_index|
        within ".offender_row_#{row_index}" do
          offender = offenders.detect { |o| o.fetch(:offenderNo) == offender_ids_by_release_date[row_index] }
          name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be sorted by cell location' do
      # Rotl's offenders are grouped when sorted by cell location. If sorted in ascending order they appear
      # at the top otherwise they are grouped at the bottom

      # ascending order
      click_link 'Location'
      within ".offender_row_0" do
        expect(page).to have_content(moved_offenders.last[:lastName])
      end

      # descending order
      click_link 'Location'
      within ".offender_row_0" do
        expect(page).to have_content(sorted_locations.last[:lastName])
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

    context 'when clicking through the offender link' do
      it 'shows the new page' do
        stub_user staff_id: nomis_staff_id

        stub_offender(first_offender)
        stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/key-worker/#{prison.code}/offender/#{first_offender.fetch(:offenderNo)}").
          to_return(body: { staffId: 485_572, firstName: "DOM", lastName: "BULL" }.to_json)
        stub_request(:get, "#{ApiHelper::T3}/staff/#{nomis_staff_id}").
          to_return(body: { staffId: nomis_staff_id, firstName: "TEST", lastName: "MOIC" }.to_json)

        visit prison_staff_caseload_path(prison.code, nomis_staff_id)

        expected_name = "#{first_offender.fetch(:lastName)}, #{first_offender.fetch(:firstName)}"

        within('.offender_row_0') do
          expect(page).to have_content(expected_name)
          click_link expected_name
        end

        expect(page).to have_current_path(prison_prisoner_path(prison.code, first_offender.fetch(:offenderNo)), ignore_query: true)
      end
    end

    it 'can sort all cases that have been allocated to a specific POM in the last week' do
      stub_user staff_id: nomis_staff_id

      visit  prison_staff_caseload_path(prison.code, nomis_staff_id)
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
end
