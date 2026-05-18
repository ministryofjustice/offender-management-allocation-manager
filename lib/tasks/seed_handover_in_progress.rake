# frozen_string_literal: true

# Run with: bundle exec rake seed:handover_in_progress POM_STAFF_ID=123456
#
# Ensures an offender allocated to the given POM appears on the
# "handovers in progress" page by creating a CalculatedHandoverDate
# record with community-responsible status and a past handover date.
#
# The offender must already have an active allocation and be unreleased
# (per the prison API). Optionally set PRISON_CODE (defaults to LEI).
#
namespace :seed do
  desc 'Set up minimum DB state for an offender to appear on the handovers in-progress page'
  task handover_in_progress: :environment do
    abort('Rails environment is running in production mode!') if Rails.env.production?

    pom_staff_id = ENV.fetch('POM_STAFF_ID') {
      puts ''
      puts '❌ POM_STAFF_ID is required.'
      puts ''
      puts 'Usage:'
      puts '  bundle exec rake seed:handover_in_progress POM_STAFF_ID=123456'
      puts ''
      exit 1
    }.to_i

    prison_code = ENV.fetch('PRISON_CODE', 'LEI')
    prison = Prison.find_by!(code: prison_code)

    allocations = AllocationHistory
      .active_allocations_for_prison(prison_code)
      .for_pom(pom_staff_id)

    # Only consider offenders that are unreleased according to the prison API
    unreleased_offender_ids = prison.unfiltered_offenders
      .select { |o| o.earliest_release_date.nil? || o.earliest_release_date > Time.zone.today }
      .map(&:offender_no)
      .to_set

    # Find an allocation whose offender doesn't already have an in-progress handover
    allocation = allocations.find do |a|
      unreleased_offender_ids.include?(a.nomis_offender_id) &&
        !CalculatedHandoverDate.exists?(
          nomis_offender_id: a.nomis_offender_id,
          responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
        )
    end

    if allocation.nil?
      puts ''
      if allocations.any?
        puts "❌ No suitable allocation found for POM #{pom_staff_id} at #{prison_code}."
        puts '   All allocations are either already in-progress or the offender\'s release date has passed.'
        puts ''
        puts 'To create a fresh test case:'
        puts '  1. Sign in as an SPO (ROLE_ALLOC_MGR).'
        puts "  2. Allocate a new offender (with a future or no release date) to POM #{pom_staff_id}."
        puts '  3. Re-run this task.'
      else
        puts "❌ No active allocation found for POM #{pom_staff_id} at #{prison_code}."
        puts ''
        puts 'Create one via the local web UI:'
        puts '  1. Sign in as an SPO (ROLE_ALLOC_MGR).'
        puts "  2. Navigate to /prisons/#{prison_code}/dashboard."
        puts "  3. Allocate an offender to POM #{pom_staff_id}."
        puts '  4. Re-run this task.'
      end
      puts ''
      exit 1
    end

    offender_id = allocation.nomis_offender_id
    offender = Offender.find_by!(nomis_offender_id: offender_id)

    puts "==> Found allocation: offender #{offender_id} at #{prison_code} (POM #{pom_staff_id})"

    # Set handover to "in progress" (community responsible with a past handover date)
    chd = offender.calculated_handover_date || offender.build_calculated_handover_date
    chd.assign_attributes(
      responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
      reason: 'determinate',
      handover_date: 2.weeks.ago.to_date,
      start_date: 6.weeks.ago.to_date,
      last_calculated_at: Time.zone.now
    )
    chd.save!

    puts ''
    puts "✅ Done! Offender #{offender_id} will now appear on the handovers in-progress page."
    puts ''
    puts "  /prisons/#{prison_code}/handovers/in_progress?pom=user&sort=handover_date+asc"
    puts ''
    puts "Handover type: #{offender.reload.handover_type}"
  end
end
