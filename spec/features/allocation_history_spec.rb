require 'rails_helper'

feature 'Allocation History' do
  let!(:probation_pom) do
    {
      primary_pom_nomis_id: 485_926,
      primary_pom_name: 'Pom, Moic',
      email: 'pom@digital.justice.gov.uk'
    }
  end

  let!(:prison_pom) do
    {
      primary_pom_nomis_id: 485_833,
      primary_pom_name: 'Heal, Jay',
      email: 'andrien.ricketts@digital.justice.gov.uk'
    }
  end

  let!(:probation_pom_2) do
    {
      primary_pom_nomis_id: 485_637,
      primary_pom_name: 'Pobee-Norris, Kath',
      email: 'kath.pobee-norris@digital.justice.gov.uk'
    }
  end

  let!(:pom_without_email) do
    {
      primary_pom_nomis_id: 485_636,
      primary_pom_name: "#{Faker::Name.last_name}, #{Faker::Name.first_name}"
    }
  end

  let!(:nomis_offender_id) { 'G4273GI' }

  scenario 'view offender allocation history', versioning: true, vcr: { cassette_name: :offender_allocation_history } do
    allocation = create(
      :allocation,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
      primary_pom_name: probation_pom[:primary_pom_name],
      recommended_pom_type: 'prison',
      override_reasons: ["suitability"],
      suitability_detail: "Too high risk",
      created_at: Time.zone.now - 10.days,
      updated_at: Time.zone.now - 10.days,
      primary_pom_allocated_at: Time.zone.now - 12.days
    )

    allocation.update!(event: Allocation::REALLOCATE_PRIMARY_POM,
                       primary_pom_nomis_id: probation_pom_2[:primary_pom_nomis_id],
                       primary_pom_name: probation_pom_2[:primary_pom_name],
                       recommended_pom_type: 'probation',
                       updated_at: Time.zone.now - 10.days
    )
    allocation.update!(event: Allocation::ALLOCATE_SECONDARY_POM,
                       secondary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
                       secondary_pom_name: probation_pom[:primary_pom_name],
                       updated_at: Time.zone.now - 8.days
    )
    allocation.update!(event: Allocation::DEALLOCATE_SECONDARY_POM,
                       secondary_pom_nomis_id: nil,
                       secondary_pom_name: nil,
                       recommended_pom_type: nil,
                       updated_at: Time.zone.now - 7.days
    )

    allocation.update!(event: Allocation::DEALLOCATE_PRIMARY_POM,
                       event_trigger: Allocation::USER,
                       primary_pom_nomis_id: nil,
                       primary_pom_name: nil,
                       recommended_pom_type: nil,
                       updated_at: Time.zone.now - 6.days,
                       primary_pom_allocated_at: nil
    )

    deallocate_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y")

    allocation.update!(event: Allocation::ALLOCATE_PRIMARY_POM,
                       prison: 'PVI',
                       primary_pom_nomis_id: prison_pom[:primary_pom_nomis_id],
                       primary_pom_name: prison_pom[:primary_pom_name],
                       recommended_pom_type: 'prison',
                       created_by_name: nil,
                       updated_at: Time.zone.now - 4.days)

    allocation.update!(event: Allocation::REALLOCATE_PRIMARY_POM,
                       primary_pom_nomis_id: pom_without_email[:primary_pom_nomis_id],
                       primary_pom_name: pom_without_email[:primary_pom_name],
                       recommended_pom_type: 'probation',
                       updated_at: Time.zone.now - 2.days)

    allocation.update!(event: Allocation::DEALLOCATE_PRIMARY_POM,
                       event_trigger: Allocation::OFFENDER_TRANSFERRED,
                       primary_pom_nomis_id: nil,
                       primary_pom_name: nil,
                       secondary_pom_nomis_id: nil,
                       secondary_pom_name: nil,
                       recommended_pom_type: nil,
                       updated_at: Time.zone.now - 1.day,
                       primary_pom_allocated_at: nil)

    transfer_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y") + " (" + allocation.updated_at.strftime("%R") + ")"

    history = offender_allocation_history(allocation)
    history1 = history[1]
    history2 = history[2]
    hist_allocate_secondary = history[5]
    history6 = history[6]

    signin_user
    visit prison_allocation_history_path('LEI', nomis_offender_id)

    stub_const("TESTS", [
        ['h1', "Abbella, Ozullirn"],
        ['.govuk-heading-m', "HMP Pentonville"],
        ['.moj-timeline__title', "Prisoner unallocated (transfer)"],
        ['.moj-timeline__date', transfer_date.to_s],
        ['.moj-timeline__title', "Prisoner reallocated"],
        ['.moj-timeline__description', "Prisoner reallocated to #{history1.primary_pom_name.titleize} - (email address not found) Tier: #{history1.allocated_at_tier}"],
        ['.moj-timeline__date', formatted_date_for(history1).to_s],
        ['.moj-timeline__title', "Prisoner allocation"],
        ['.moj-timeline__description', "Prisoner allocated to #{history2.primary_pom_name.titleize} - #{prison_pom[:email]} Tier: #{history2.allocated_at_tier}"],
        ['.moj-timeline__date', formatted_date_for(history2).to_s],
        ['.moj-timeline__description', "Prisoner allocated to #{hist_allocate_secondary.secondary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{hist_allocate_secondary.allocated_at_tier}"],
        ['.moj-timeline__date', "#{formatted_date_for(hist_allocate_secondary)} by #{hist_allocate_secondary.created_by_name.titleize}"],
        ['.govuk-heading-m', "HMP Leeds"],
        ['.moj-timeline__title', "Prisoner unallocated"],
        ['.moj-timeline__title', "Co-working unallocated"],
        ['.moj-timeline__date', deallocate_date.to_s],
        ['.moj-timeline__title', "Prisoner reallocated"],
        ['.moj-timeline__description', "Prisoner reallocated to #{history6.primary_pom_name.titleize} - #{probation_pom_2[:email]} Tier: #{history6.allocated_at_tier}"],
        ['.moj-timeline__date', "#{formatted_date_for(history6)} by #{history6.created_by_name.titleize}"],
        ['.moj-timeline__title', "Prisoner allocation"],
        ['.moj-timeline__description', "Prisoner allocated to #{history.last.primary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{history.last.allocated_at_tier}"],
        ['.moj-timeline__description', "Probation POM allocated instead of recommended Prison POM", "Reason(s):", "- Prisoner assessed as suitable for a prison POM despite tiering calculation", "Too high risk"],
        ['.moj-timeline__date', "#{formatted_date_for(history.last)} by #{history.last.created_by_name.titleize}"]
    ])

    TESTS.each do |key, val|
      expect(page).to have_css(key, text: val)
    end
  end

  def formatted_date_for(history)
    history.updated_at.strftime("#{history.updated_at.day.ordinalize} %B %Y") + " (" + history.updated_at.strftime("%R") + ")"
  end

  def offender_allocation_history(current_allocation)
    AllocationService.get_versions_for(current_allocation).
      append(current_allocation).
      sort_by!(&:updated_at).
      reverse!
  end
end
