require 'rails_helper'

feature 'Allocation History' do
  let!(:probation_pom) do
    {
      primary_pom_nomis_id: 485_752,
      primary_pom_name: 'Ross Jones',
      email: 'Ross.jonessss@digital.justice.gov.uk'
    }
  end

  let!(:prison_pom) do
    {
      primary_pom_nomis_id: 485_737,
      primary_pom_name: 'Jay Heal',
      email: 'jay.heal@digital.justice.gov.uk'
    }
  end

  let!(:probation_pom_2) do
    {
      primary_pom_nomis_id: 485_637,
      primary_pom_name: 'Kath Pobee-Norris',
      email: 'kath.pobee-norris@digital.justice.gov.uk'
    }
  end

  let!(:pom_without_email) do
    {
      primary_pom_nomis_id: 485_636,
      primary_pom_name: "#{Faker::Name.first_name} #{Faker::Name.last_name}"
    }
  end

  let!(:nomis_offender_id) { 'G4273GI' }

  scenario 'view offender allocation history', versioning: true, vcr: { cassette_name: :offender_allocation_history } do
    create(
      :allocation_version,
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

    allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

    allocation.update!(event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                       primary_pom_nomis_id: probation_pom_2[:primary_pom_nomis_id],
                       primary_pom_name: probation_pom_2[:primary_pom_name],
                       recommended_pom_type: 'probation',
                       updated_at: Time.zone.now - 10.days
    )
    allocation.update!(event: AllocationVersion::ALLOCATE_SECONDARY_POM,
                       secondary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
                       secondary_pom_name: probation_pom[:primary_pom_name],
                       updated_at: Time.zone.now - 8.days
    )
    allocation.update!(event: AllocationVersion::DEALLOCATE_SECONDARY_POM,
                       secondary_pom_nomis_id: nil,
                       secondary_pom_name: nil,
                       recommended_pom_type: nil,
                       updated_at: Time.zone.now - 7.days
    )

    allocation.update!(event: AllocationVersion::DEALLOCATE_PRIMARY_POM,
                       event_trigger: AllocationVersion::USER,
                       primary_pom_nomis_id: nil,
                       primary_pom_name: nil,
                       recommended_pom_type: nil,
                       updated_at: Time.zone.now - 6.days,
                       primary_pom_allocated_at: nil
    )

    deallocate_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y")

    allocation.update!(event: AllocationVersion::ALLOCATE_PRIMARY_POM,
                       prison: 'PVI',
                       primary_pom_nomis_id: prison_pom[:primary_pom_nomis_id],
                       primary_pom_name: prison_pom[:primary_pom_name],
                       recommended_pom_type: 'prison',
                       created_by_name: nil,
                       updated_at: Time.zone.now - 4.days)

    allocation.update!(event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                       primary_pom_nomis_id: pom_without_email[:primary_pom_nomis_id],
                       primary_pom_name: pom_without_email[:primary_pom_name],
                       recommended_pom_type: 'probation',
                       updated_at: Time.zone.now - 2.days)

    allocation.update!(event: AllocationVersion::DEALLOCATE_PRIMARY_POM,
                       event_trigger: AllocationVersion::OFFENDER_TRANSFERRED,
                       primary_pom_nomis_id: nil,
                       primary_pom_name: nil,
                       secondary_pom_nomis_id: nil,
                       secondary_pom_name: nil,
                       recommended_pom_type: nil,
                       updated_at: Time.zone.now - 1.day,
                       primary_pom_allocated_at: nil)

    transfer_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y") + " (" + allocation.updated_at.strftime("%R") + ")"

    history = AllocationService.offender_allocation_history(nomis_offender_id)
    history1 = history[1]
    history2 = history[2]
    hist_allocate_secondary = history[5]
    history6 = history[6]

    signin_user
    visit prison_allocation_history_path('LEI', nomis_offender_id)

    stub_const("TESTS", [
        ['h1', "Abbella, Ozullirn"],
        ['.govuk-heading-m', "HMP Pentonville"],
        ['.govuk-heading-s', "Prisoner unallocated (transfer)"],
        ['.time', transfer_date.to_s],
        ['.govuk-heading-s', "Prisoner reallocated"],
        ['p', "Prisoner reallocated to #{history1.primary_pom_name} - (email address not found) Tier: #{history1.allocated_at_tier}"],
        ['.time', formatted_date_for(history1).to_s],
        ['.govuk-heading-s', "Prisoner allocation"],
        ['p', "Prisoner allocated to #{history2.primary_pom_name.titleize} - #{prison_pom[:email]} Tier: #{history2.allocated_at_tier}"],
        ['.time', formatted_date_for(history2).to_s],
        ['p', "Prisoner allocated to #{hist_allocate_secondary.secondary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{hist_allocate_secondary.allocated_at_tier}"],
        ['.time', "#{formatted_date_for(hist_allocate_secondary)} by #{hist_allocate_secondary.created_by_name.titleize}"],
        ['.govuk-heading-m', "HMP Leeds"],
        ['.govuk-heading-s', "Prisoner unallocated"],
        ['.govuk-heading-s', "Co-working unallocated"],
        ['.time', deallocate_date.to_s],
        ['.govuk-heading-s', "Prisoner reallocated"],
        ['p', "Prisoner reallocated to #{history6.primary_pom_name} - #{probation_pom_2[:email]} Tier: #{history6.allocated_at_tier}"],
        ['.time', "#{formatted_date_for(history6)} by #{history6.created_by_name.titleize}"],
        ['.govuk-heading-s', "Prisoner allocation"],
        ['p', "Prisoner allocated to #{history.last.primary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{history.last.allocated_at_tier}"],
        ['p', "Probation POM allocated instead of recommended Prison POM", "Reason(s):", "- Prisoner assessed as suitable for a prison POM despite tiering calculation", "Too high risk"],
        ['.time', "#{formatted_date_for(history.last)} by #{history.last.created_by_name.titleize}"]
    ])

    TESTS.each do |key, val|
      expect(page).to have_css(key, text: val)
    end
  end

  def formatted_date_for(history)
    history.updated_at.strftime("#{history.updated_at.day.ordinalize} %B %Y") + " (" + history.updated_at.strftime("%R") + ")"
  end
end
