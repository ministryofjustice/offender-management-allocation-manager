# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'List all prisons having removed/ghost POMs with primary cases in limbo (attention needed)'
  task limbo_cases: :environment do
    puts 'Report started'

    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    total_prisons = 0
    total_removed_poms = 0
    total_ghost_poms = 0
    total_cases = 0
    active_prison_codes = Prison.active.order(:name).pluck(:code)

    active_prison_codes.each do |prison_code|
      prison = Prison.find_by!(code: prison_code)

      poms = prison.get_list_of_poms
      existing_pom_ids = poms.map(&:staff_id)
      allocated_offender_nos = prison.allocated.map(&:offender_no)

      relevant_allocations = AllocationHistory.active_allocations_for_prison(prison_code)
        .where(nomis_offender_id: allocated_offender_nos)
        .where.not(primary_pom_nomis_id: existing_pom_ids)

      # Free the heavy offender data immediately as otherwise we may get OOM
      prison.remove_instance_variable(:@summary) if prison.instance_variable_defined?(:@summary)
      prison.remove_instance_variable(:@unfiltered_offenders) if prison.instance_variable_defined?(:@unfiltered_offenders)
      prison.remove_instance_variable(:@allocations) if prison.instance_variable_defined?(:@allocations)
      prison.remove_instance_variable(:@allocations_by_offender_nomis_id) if prison.instance_variable_defined?(:@allocations_by_offender_nomis_id)

      unless relevant_allocations.exists?
        GC.start
        next
      end

      # Removed POMs: have a PomDetail but are no longer in the NOMIS POM list
      removed_pom_detail_ids = prison.pom_details.where.not(nomis_staff_id: existing_pom_ids)
        .pluck(:nomis_staff_id)

      removed_ids = relevant_allocations
        .where(primary_pom_nomis_id: removed_pom_detail_ids)
        .distinct.pluck(:primary_pom_nomis_id)

      # Ghost POMs: have active allocations but no PomDetail record at all
      known_pom_ids = existing_pom_ids + prison.pom_details.pluck(:nomis_staff_id)
      ghost_ids = relevant_allocations
        .where.not(primary_pom_nomis_id: known_pom_ids)
        .distinct.pluck(:primary_pom_nomis_id)

      GC.start

      next if removed_ids.empty? && ghost_ids.empty?

      removed_cases = relevant_allocations.where(primary_pom_nomis_id: removed_ids).count
      ghost_cases = relevant_allocations.where(primary_pom_nomis_id: ghost_ids).count
      prison_total_cases = removed_cases + ghost_cases

      puts "\n==> #{prison.name} (#{prison.code})"
      puts "    Removed POMs: #{removed_ids.size} (#{removed_cases} primary cases)"
      puts "    Ghost POMs:   #{ghost_ids.size} (#{ghost_cases} primary cases)"
      puts "    Total:        #{removed_ids.size + ghost_ids.size} POMs, #{prison_total_cases} cases"

      total_prisons += 1
      total_removed_poms += removed_ids.size
      total_ghost_poms += ghost_ids.size
      total_cases += prison_total_cases
    end

    puts "\n#{'=' * 80}"
    puts 'Summary'
    puts '-' * 80
    puts "Prisons affected:    #{total_prisons} out of #{active_prison_codes.size}"
    puts "Removed POMs:        #{total_removed_poms}"
    puts "Ghost POMs:          #{total_ghost_poms}"
    puts "Total POMs:          #{total_removed_poms + total_ghost_poms}"
    puts "Total primary cases: #{total_cases}"
    puts "\n"
  end
end
