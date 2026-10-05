# frozen_string_literal: true

namespace :reports do
  desc 'Report significant changes across all prisons, with tier, ROSH and handover counts'
  task significant_changes: :environment do
    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    volumes = []

    Prison.find_each do |prison|
      puts "Processing #{prison.code}..."

      allocations = AllocationHistory.active_allocations_for_prison(prison.code)
        .where.not(primary_pom_allocated_at: nil).to_a

      # Without recent tracked versions, no detector can qualify a case; avoid all live API calls.
      reviews = []
      if allocations.any? && SignificantChanges.load_versions(allocations).exists?
        poms = nil
        reviews = SignificantChanges.for(
          prison.allocated,
          prison.allocations,
          poms: -> { poms ||= prison.get_list_of_poms(include_deleted: true) }
        ).select(&:any?)
      end

      breakdown = reviews.flat_map { it.changes.map(&:type) }.tally
      row = {
        code: prison.code,
        name: prison.name,
        total: reviews.size,
        tier: breakdown.fetch(:tier, 0),
        rosh: breakdown.fetch(:rosh, 0),
        handover: breakdown.fetch(:handover, 0)
      }
      volumes << row

      puts "#{row[:code]}: #{row[:total]} cases " \
           "(tier: #{row[:tier]}, ROSH: #{row[:rosh]}, handover: #{row[:handover]})"
    end

    puts "\nPrison | Name | Total cases | Tier | ROSH | Handover"
    volumes.sort_by { [-it[:total], it[:code]] }.each do |row|
      puts row.values_at(:code, :name, :total, :tier, :rosh, :handover).join(' | ')
    end

    puts "\nOverall:"
    [:total, :tier, :rosh, :handover].each do |key|
      puts "#{key}: #{volumes.sum { it[key] }}"
    end
  end
end
