# frozen_string_literal: true

namespace :prune do
  desc 'Prune orphaned CaseInformation records: dry-run mode (report only, no changes). ' \
       'Optionally set PRUNE_MIN_AGE_MONTHS=3 and/or PRUNE_BATCH_SIZE=500.'
  task dry_run: :environment do
    min_age_months = Integer(ENV.fetch('PRUNE_MIN_AGE_MONTHS', PruneOrphanedCaseDataService::DEFAULT_NEVER_ALLOCATED_MIN_AGE_MONTHS))
    batch_size = Integer(ENV.fetch('PRUNE_BATCH_SIZE', PruneOrphanedCaseDataService::DEFAULT_BATCH_SIZE))

    puts("[prune] starting dry_run=true min_age_months=#{min_age_months} batch_size=#{batch_size}")

    result = PruneOrphanedCaseDataService.new(
      dry_run: true,
      never_allocated_min_age: min_age_months.months,
      batch_size:
    ).call

    puts(
      "[prune] dry_run=#{result.dry_run} " \
      "never_allocated=#{result.never_allocated_count} " \
      "released_via_allocation=#{result.released_allocation_count} " \
      "total=#{result.total_count}"
    )

    sample_ids = (result.never_allocated_ids | result.released_allocation_ids).first(10)
    puts("[prune] sample_nomis_offender_ids=#{sample_ids.join(',')}") if sample_ids.any?
  end

  desc 'Prune orphaned CaseInformation records: process mode (deletes stale data). ' \
       'Optionally set PRUNE_MIN_AGE_MONTHS=3 and/or PRUNE_BATCH_SIZE=500.'
  task process: :environment do
    min_age_months = Integer(ENV.fetch('PRUNE_MIN_AGE_MONTHS', PruneOrphanedCaseDataService::DEFAULT_NEVER_ALLOCATED_MIN_AGE_MONTHS))
    batch_size = Integer(ENV.fetch('PRUNE_BATCH_SIZE', PruneOrphanedCaseDataService::DEFAULT_BATCH_SIZE))

    puts("[prune] starting dry_run=false min_age_months=#{min_age_months} batch_size=#{batch_size}")

    result = PruneOrphanedCaseDataService.new(
      dry_run: false,
      never_allocated_min_age: min_age_months.months,
      batch_size:
    ).call

    puts(
      "[prune] dry_run=#{result.dry_run} " \
      "never_allocated=#{result.never_allocated_count} " \
      "released_via_allocation=#{result.released_allocation_count} " \
      "total_pruned=#{result.total_count}"
    )
  end
end
