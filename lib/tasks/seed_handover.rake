# frozen_string_literal: true

# Run with: bundle exec rake seed:handover POM_STAFF_ID=123456 LIST=in_progress|upcoming
#
# Ensures an offender allocated to the given POM appears on the
# specified handover page by creating a CalculatedHandoverDate record
# with the appropriate responsibility and dates.
#
# LIST must be either in_progress or upcoming.
#
# The offender must already have an active allocation and be unreleased
# (per the prison API). Optionally set PRISON_CODE (defaults to LEI).
#
namespace :seed do
  desc 'Set up minimum DB state for an offender to appear on a handover page (in_progress or upcoming)'
  task handover: :environment do
    abort('Rails environment is running in production mode!') if Rails.env.production?

    pom_staff_id = ENV.fetch('POM_STAFF_ID') {
      puts ''
      puts '❌ POM_STAFF_ID is required.'
      puts ''
      puts 'Usage:'
      puts '  bundle exec rake seed:handover POM_STAFF_ID=123456 LIST=in_progress|upcoming'
      puts ''
      exit 1
    }.to_i

    list = ENV.fetch('LIST') do
      puts ''
      puts '❌ LIST is required.'
      puts ''
      puts 'Usage:'
      puts '  bundle exec rake seed:handover POM_STAFF_ID=123456 LIST=in_progress|upcoming'
      puts ''
      exit 1
    end
    unless %w[in_progress upcoming].include?(list)
      puts ''
      puts "❌ LIST must be 'in_progress' or 'upcoming' (got '#{list}')."
      puts ''
      exit 1
    end

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

    # Find an allocation whose offender doesn't already have a matching handover
    target_responsibility = list == 'in_progress' ? CalculatedHandoverDate::COMMUNITY_RESPONSIBLE : CalculatedHandoverDate::CUSTODY_ONLY

    allocation = allocations.find do |a|
      unreleased_offender_ids.include?(a.nomis_offender_id) &&
        !CalculatedHandoverDate.exists?(
          nomis_offender_id: a.nomis_offender_id,
          responsibility: target_responsibility
        )
    end

    if allocation.nil?
      puts ''
      if allocations.any?
        puts "❌ No suitable allocation found for POM #{pom_staff_id} at #{prison_code}."
        puts '   All allocations already have a matching handover or the offender\'s release date has passed.'
        puts ''
        puts 'To create a fresh test case:'
        puts '  1. Sign in as an SPO (ROLE_ALLOC_MGR).'
        puts "  2. Allocate a new offender (with a future or no release date) to POM #{pom_staff_id}."
      else
        puts "❌ No active allocation found for POM #{pom_staff_id} at #{prison_code}."
        puts ''
        puts 'Create one via the local web UI:'
        puts '  1. Sign in as an SPO (ROLE_ALLOC_MGR).'
        puts "  2. Allocate an offender to POM #{pom_staff_id}."
      end
      puts '  3. Re-run this task.'
      puts ''
      exit 1
    end

    offender_id = allocation.nomis_offender_id
    offender = Offender.find_by!(nomis_offender_id: offender_id)

    puts "==> Found allocation: offender #{offender_id} at #{prison_code} (POM #{pom_staff_id})"

    chd = offender.calculated_handover_date || offender.build_calculated_handover_date

    if list == 'in_progress'
      chd.assign_attributes(
        responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
        reason: 'determinate',
        handover_date: 2.weeks.ago.to_date,
        start_date: 6.weeks.ago.to_date,
        last_calculated_at: Time.zone.now
      )
    else
      chd.assign_attributes(
        responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
        reason: 'determinate',
        handover_date: 4.weeks.from_now.to_date,
        start_date: 4.weeks.from_now.to_date,
        last_calculated_at: Time.zone.now
      )
    end

    chd.save!

    page_path = "/prisons/#{prison_code}/handovers/#{list}?pom=user&sort=handover_date+asc"

    puts ''
    puts "✅ Done! Offender #{offender_id} will now appear on the handovers #{list.tr('_', ' ')} page."
    puts ''
    puts "  #{page_path}"
    puts ''
    puts "Handover type: #{offender.reload.handover_type}"
  end
end
