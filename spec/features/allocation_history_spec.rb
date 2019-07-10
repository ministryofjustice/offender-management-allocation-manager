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
        primary_pom_name: "#{Faker::Name.first_name} #{Faker::Name.last_name}",
    }
  end

  let!(:nomis_offender_id) { 'G4273GI' }

  scenario 'view offender allocation history', versioning: true, vcr: { cassette_name: :offender_allocation_history } do

    create(
        :allocation_version,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
        primary_pom_name: probation_pom[:primary_pom_name],
        recommended_pom_type: 'probation',
        created_at: Time.zone.now - 10.days,
        updated_at: Time.zone.now - 10.days,
        primary_pom_allocated_at: Time.zone.now - 10.days
    )

    allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)

    allocation.update(event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                      primary_pom_nomis_id: probation_pom_2[:primary_pom_nomis_id],
                      primary_pom_name: probation_pom_2[:primary_pom_name],
                      recommended_pom_type: 'probation',
                      updated_at: Time.zone.now - 8.days
    )

    allocation.update(event: AllocationVersion::DEALLOCATE_PRIMARY_POM,
                      event_trigger: AllocationVersion::USER,
                      primary_pom_nomis_id: nil,
                      primary_pom_name: nil,
                      recommended_pom_type: nil,
                      updated_at: Time.zone.now - 6.days,
                      primary_pom_allocated_at: nil
    )

    deallocate_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y")

    allocation.update(event: AllocationVersion::ALLOCATE_PRIMARY_POM,
                      prison: 'PVI',
                      primary_pom_nomis_id: prison_pom[:primary_pom_nomis_id],
                      primary_pom_name: prison_pom[:primary_pom_name],
                      recommended_pom_type: 'prison',
                      updated_at: Time.zone.now - 4.day)

    allocation.update(event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                      primary_pom_nomis_id: pom_without_email[:primary_pom_nomis_id],
                      primary_pom_name: pom_without_email[:primary_pom_name],
                      recommended_pom_type: 'probation',
                      updated_at: Time.zone.now - 2.days)

    allocation.update(event: AllocationVersion::DEALLOCATE_PRIMARY_POM,
                      event_trigger: AllocationVersion::OFFENDER_TRANSFERRED,
                      primary_pom_nomis_id: nil,
                      primary_pom_name: nil,
                      recommended_pom_type: nil,
                      updated_at: Time.zone.now - 1.day,
                      primary_pom_allocated_at: nil)

    transfer_date = allocation.updated_at.strftime("#{allocation.updated_at.day.ordinalize} %B %Y") + " (" + allocation.updated_at.strftime("%R") + ")"

    history = AllocationService.offender_allocation_history(nomis_offender_id)

    signin_user
    visit prison_allocation_history_path('LEI', nomis_offender_id)

    expect(page).to have_css('h1', text: "Abbella, Ozullirn")

    expect(page).to have_css('.govuk-heading-m', text: "HMP Pentonville")

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner unallocated (transfer)")
    expect(page).to have_css('.time', text: transfer_date.to_s)

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner reallocated")
    expect(page).to have_css('p', text: "Prisoner reallocated to #{history[1].primary_pom_name} Tier: #{history[1].allocated_at_tier}")
    previous_formatted_date = history[1].updated_at.strftime("#{history[1].updated_at.day.ordinalize} %B %Y") + " (" + history[1].updated_at.strftime("%R") + ")"
    expect(page).to have_css('.time', text: "#{previous_formatted_date} by #{history[1].created_by_name.titleize}")

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner allocation")
    expect(page).to have_css('p', text: "Prisoner allocated to #{history[2].primary_pom_name.titleize} - #{prison_pom[:email]} Tier: #{history[2].allocated_at_tier}")
    pvi_allocation_date = history[2].updated_at.strftime("#{history[2].updated_at.day.ordinalize} %B %Y") + " (" + history[2].updated_at.strftime("%R") + ")"
    expect(page).to have_css('.time', text: "#{pvi_allocation_date} by #{history[2].created_by_name.titleize}")

    expect(page).to have_css('.govuk-heading-m', text: "HMP Leeds")

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner unallocated")
    expect(page).to have_css('.time', text: deallocate_date.to_s)

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner reallocated")
    expect(page).to have_css('p', text: "Prisoner reallocated to #{history[4].primary_pom_name} - #{probation_pom_2[:email]} Tier: #{history[4].allocated_at_tier}")
    old_formatted_date = history[4].updated_at.strftime("#{history[4].updated_at.day.ordinalize} %B %Y") + " (" + history[4].updated_at.strftime("%R") + ")"
    expect(page).to have_css('.time', text: "#{old_formatted_date} by #{history[4].created_by_name.titleize}")

    expect(page).to have_css('.govuk-heading-s', text: "Prisoner allocation")
    expect(page).to have_css('p', text: "Prisoner allocated to #{history.last.primary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{history.last.allocated_at_tier}")
    initial_allocated_date = history.last.updated_at.strftime("#{history.last.updated_at.day.ordinalize} %B %Y") + " (" + history.last.updated_at.strftime("%R") + ")"
    expect(page).to have_css('.time', text: "#{initial_allocated_date} by #{history.last.created_by_name.titleize}")
  end
end
