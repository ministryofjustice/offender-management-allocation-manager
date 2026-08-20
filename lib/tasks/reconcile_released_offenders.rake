# frozen_string_literal: true

namespace :reconcile do
  desc 'Manual backlog cleanup for confirmed released offenders: dry-run mode (report only, no changes). ' \
       'Optionally set PRISON_CODE=LEI or PRISON_CODE=LEI,MDI and/or RECONCILE_BATCH_SIZE=500.'
  task dry_run: :environment do
    prison_codes = ENV['PRISON_CODE']&.split(',')&.map(&:strip)
    batch_size = Integer(ENV.fetch('RECONCILE_BATCH_SIZE', ReconcileReleasedOffendersService::DEFAULT_BATCH_SIZE))

    puts("[reconcile] starting dry_run=true prison_scope=#{prison_codes&.join(',') || 'ALL'} batch_size=#{batch_size}")

    result = ReconcileReleasedOffendersService.new(dry_run: true, prison_codes:, batch_size:).call

    puts(
      "[reconcile] dry_run=#{result.dry_run} candidates=#{result.candidate_count} " \
      "confirmed_released=#{result.released_count} not_confirmed=#{result.skipped_count} " \
      "unresolved=#{result.unresolved_count}"
    )
    puts(
      "[reconcile] api_resolution candidates=#{result.api_resolution_candidates_count} " \
      "found_in_search=#{result.api_found_in_search_count} " \
      "resolved_to_target_prisons=#{result.api_resolved_to_target_prisons_count} " \
      "resolved_to_other_prisons=#{result.api_resolved_to_other_prisons_count} " \
      "not_found_in_search=#{result.api_not_found_in_search_count}"
    )
    puts("[reconcile] released_nomis_ids=#{result.released_ids.to_a.sort.join(',')}") if result.released_ids.any?
  end

  desc 'Manual backlog cleanup for confirmed released offenders: process mode (clean up orphaned data). ' \
       'Optionally set PRISON_CODE=LEI or PRISON_CODE=LEI,MDI and/or RECONCILE_BATCH_SIZE=500.'
  task process: :environment do
    prison_codes = ENV['PRISON_CODE']&.split(',')&.map(&:strip)
    batch_size = Integer(ENV.fetch('RECONCILE_BATCH_SIZE', ReconcileReleasedOffendersService::DEFAULT_BATCH_SIZE))

    puts("[reconcile] starting dry_run=false prison_scope=#{prison_codes&.join(',') || 'ALL'} batch_size=#{batch_size}")

    result = ReconcileReleasedOffendersService.new(dry_run: false, prison_codes:, batch_size:).call

    puts(
      "[reconcile] dry_run=#{result.dry_run} candidates=#{result.candidate_count} " \
      "confirmed_released=#{result.released_count} not_confirmed=#{result.skipped_count} " \
      "unresolved=#{result.unresolved_count}"
    )
    puts(
      "[reconcile] api_resolution candidates=#{result.api_resolution_candidates_count} " \
      "found_in_search=#{result.api_found_in_search_count} " \
      "resolved_to_target_prisons=#{result.api_resolved_to_target_prisons_count} " \
      "resolved_to_other_prisons=#{result.api_resolved_to_other_prisons_count} " \
      "not_found_in_search=#{result.api_not_found_in_search_count}"
    )
    puts("[reconcile] released_nomis_ids=#{result.released_ids.to_a.sort.join(',')}") if result.released_ids.any?
  end
end
