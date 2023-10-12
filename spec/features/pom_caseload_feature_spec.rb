# frozen_string_literal: true

require "rails_helper"

feature "view POM's caseload" do
  let(:nomis_staff_id) { 485_926 }
  let(:nomis_offender_id) { 'G4273GI' }
  let(:tomorrow) { Date.tomorrow }
  let(:other_pom) { build(:pom) }

  let(:offender_map) do
    {
      'G7266VD' => 1_073,
      'G8563UA' => 5,
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
      'G1992GH' => 6,
      'G1986GG' => 1_165,
      'G6262GI' => 961,
      'G6653UC' => 1_009,
      'G5992GA' => 7,
      'G4706UP' => 1_180,
      'G9344UG' => 841
    }
  end
  let(:nil_release_date_offender) { 'G9372GQ' }
  let(:offender_ids_by_release_date) do
    offender_map.excluding(nil_release_date_offender).map { |k, v| [k, v] }.sort_by { |_k, v| v }.map { |k, _v| k }
  end
  let(:offenders) do
    ids_without_cells = %w[G6653UC G8563UA]
    offender_map.merge(nomis_offender_id => 1_153)
      .map do |nomis_id, booking_id|
      if ids_without_cells.include? nomis_id
        # generate 2 offenders without a cell location
        build(:nomis_offender, cellLocation: nil,
                               prisonId: prison.code,
                               prisonerNumber: nomis_id,
                               sentence: attributes_for(:sentence_detail,
                                                        automaticReleaseDate: "2031-01-22",
                                                        conditionalReleaseDate: "2031-01-24",
                                                        tariffDate: (nomis_id == nil_release_date_offender) ? nil : Time.zone.today + booking_id.days))
      else
        build(:nomis_offender,
              prisonId: prison.code,
              prisonerNumber: nomis_id,
              sentence: attributes_for(:sentence_detail,
                                       automaticReleaseDate: "2031-01-22",
                                       conditionalReleaseDate: "2031-01-24",
                                       tariffDate: (nomis_id == nil_release_date_offender) ? nil : Time.zone.today + booking_id.days))
      end
    end
  end
  let(:missing_cells) do
    offenders.find_all { |x| x[:cellLocation].nil? }
  end
  let(:sorted_offenders) do
    offenders.sort_by { |o| o.fetch(:lastName) }
  end
  let(:first_offender) { sorted_offenders.first }
  let(:last_offender) { sorted_offenders.last }
  let(:moved_offenders) { [sorted_offenders.fourth, sorted_offenders.fifth] }

  let(:sorted_locations) do
    removed_list = [moved_offenders.first, moved_offenders.last, missing_cells.first, missing_cells.last]
    offenders.reject { |x| removed_list.include? x }.sort_by { |o| o.fetch(:cellLocation) }
  end

  # create 21 allocations for prisoners named A-K so that we can verify that default sorted paging works
  before do
    allow_any_instance_of(DomainEvents::Event).to receive(:publish).and_return(nil)
    poms =
      [
        build(:pom,
              firstName: 'Alice',
              position: RecommendationService::PRISON_POM,
              staffId: nomis_staff_id
             ),
        other_pom
      ]

    stub_auth_token
    stub_poms(prison.code, poms)
    signin_pom_user [prison.code]

    # Add attributes to moved_offenders to make them ROTLs - needed in conjunction with the ROTL movements
    moved_offenders.each do |o|
      o.merge!(inOutStatus: 'OUT', lastMovementTypeCode: 'TAP')
    end

    stub_offenders_for_prison(prison.code, offenders, [
      attributes_for(:movement, :rotl, movementDate: Time.zone.today - 1.month, offenderNo: moved_offenders.first.fetch(:prisonerNumber)),
      attributes_for(:movement, :rotl, movementDate: Time.zone.today - 1.year, offenderNo: moved_offenders.last.fetch(:prisonerNumber))
    ])

    offender_map.each do |nomis_offender_id, _nomis_booking_id|
      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
      create(:allocation_history, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id)
    end
    create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id), tier: 'A', enhanced_resourcing: true, probation_service: 'Wales')
    coworking = create(:allocation_history, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: other_pom.staff_id)
    coworking.update!(secondary_pom_nomis_id: nomis_staff_id, event: AllocationHistory::ALLOCATE_SECONDARY_POM)

    offenders.last(15).each do |o|
      create(:responsibility, nomis_offender_id: o.fetch(:prisonerNumber), value: Responsibility::PROBATION)
    end

    allow_any_instance_of(MpcOffender).to receive(:handover_start_date).and_return(tomorrow)

    stub_user staff_id: nomis_staff_id
  end

  context 'when in a womens prison' do
    let(:prison) { create(:womens_prison) }
    let(:complexities) { %w[high medium low].cycle.take(offenders.size) }

    before do
      offenders.each_with_index do |offender, index|
        allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender.fetch(:prisonerNumber)).and_return(complexities[index])
      end
      visit prison_staff_caseload_cases_path(prison.code, nomis_staff_id)
    end

    it 'can sort by complexity' do
      find('#all-cases .govuk-table').click_link 'Complexity level'
      expect(page).to have_current_path("/prisons/#{prison.code}/staff/#{nomis_staff_id}/caseload/cases?sort=complexity_level_number+asc")
      find('#all-cases .govuk-table').click_link 'Complexity level'
      expect(page).to have_current_path("/prisons/#{prison.code}/staff/#{nomis_staff_id}/caseload/cases?sort=complexity_level_number+desc")
    end
  end

  context 'when in a mens prison' do
    let(:prison) { create(:prison) }

    before do
      visit prison_staff_caseload_cases_path(prison.code, nomis_staff_id)
    end

    it 'displays paginated cases for a specific POM' do
      expect(page).to have_content("Showing 1 to 21 of 21 results")
      expect(page).to have_content("Your cases")
      expect(page).to have_content("All your cases")
      sorted_offenders.first(20).each_with_index do |offender, index|
        name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"

        within "#all-cases .offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be reverse sorted by name' do
      click_link 'All your cases'
      find('#all-cases .govuk-table').click_link 'Case'
      sorted_offenders.last(20).reverse.each_with_index do |offender, index|
        name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"
        within "#all-cases .offender_row_#{index}" do
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be sorted by earliest release date' do
      find('#all-cases .govuk-table').click_link 'Earliest release date'
      # pick out a few rows, and make sure they are in order by release date
      (2..7).each do |row_index|
        within "#all-cases .offender_row_#{row_index}" do
          offender = offenders.detect { |o| o.fetch(:prisonerNumber) == offender_ids_by_release_date[row_index] }
          name = "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}"
          expect(page).to have_content(name)
        end
      end
    end

    it 'can be sorted by responsibility' do
      find('#all-cases .govuk-table').click_link 'Role'
      expect(all('td[aria-label=Role]').map(&:text).uniq).to eq(%w[Co-working Responsible Supporting])
      find('#all-cases .govuk-table').click_link 'Role'
      expect(all('td[aria-label=Role]').map(&:text).uniq).to eq(%w[Supporting Responsible Co-working])
    end

    it 'can be sorted by cell location' do
      # Rotl's offenders are grouped when sorted by cell location. If sorted in ascending order they appear
      # at the top otherwise they are grouped at the bottom

      # ascending order
      find('#all-cases .govuk-table').click_link 'Location'
      within "#all-cases .offender_row_0" do
        expect(page).to have_content(moved_offenders.last[:lastName])
      end

      # descending order
      find('#all-cases .govuk-table').click_link 'Location'
      within "#all-cases .offender_row_0" do
        expect(page).to have_content(sorted_locations.last[:lastName])
      end
    end

    it 'shows the tier' do
      within('#all-cases .offender_row_20 .tier') do
        expect(page).to have_content('A')
      end
    end

    it 'shows the number of upcoming handovers' do
      expect(find('a[href="#upcoming-releases"]').text).to eq('Releases in next 4 weeks (3)')
    end

    it 'can show us all upcoming handovers' do
      find('a[href="#upcoming-releases"]').click
      expect(page).to have_css('#upcoming-releases tbody tr.govuk-table__row', count: 3)
    end

    context 'when clicking through the offender link' do
      it 'shows the new page' do
        stub_user staff_id: nomis_staff_id

        stub_offender(first_offender)
        stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/key-worker/#{prison.code}/offender/#{first_offender.fetch(:prisonerNumber)}")
          .to_return(body: { staffId: 485_572, firstName: "DOM", lastName: "BULL" }.to_json)
        stub_request(:get, "#{ApiHelper::T3}/staff/#{nomis_staff_id}")
          .to_return(body: { staffId: nomis_staff_id, firstName: "TEST", lastName: "MOIC" }.to_json)

        visit prison_staff_caseload_cases_path(prison.code, nomis_staff_id)

        expected_name = "#{first_offender.fetch(:lastName)}, #{first_offender.fetch(:firstName)}"

        within('#all-cases .offender_row_0') do
          expect(page).to have_content(expected_name)
          click_link expected_name
        end

        expect(page).to have_current_path(prison_prisoner_path(prison.code, first_offender.fetch(:prisonerNumber)), ignore_query: true)
      end
    end

    it 'can sort all cases that have been allocated to a specific POM in the last week' do
      stub_user staff_id: nomis_staff_id
      expect(find('a[href="#recent-allocations"]').text).to eq('Allocated in last 7 days (21)')

      # The first name...
      within('#recent-allocations .offender_row_0') do
        expect(find('.prisoner-name').text).to eq("#{first_offender.fetch(:lastName)}, #{first_offender.fetch(:firstName)}")
      end

      # Should be the last name
      within('#recent-allocations .offender_row_20') do
        expect(find('.prisoner-name').text).to eq("#{last_offender.fetch(:lastName)}, #{last_offender.fetch(:firstName)}")
      end

      # After sorting ...
      find('#recent-allocations .govuk-table').click_link('Case')

      # The last name...
      within('#recent-allocations .offender_row_0') do
        expect(find('.prisoner-name').text).to eq("#{last_offender.fetch(:lastName)}, #{last_offender.fetch(:firstName)}")
      end

      # Should be the last name
      within('#recent-allocations .offender_row_20') do
        expect(find('.prisoner-name').text).to eq("#{first_offender.fetch(:lastName)}, #{first_offender.fetch(:firstName)}")
      end
    end
  end
end
