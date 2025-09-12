# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'List all prisons having removed POMs with cases in limbo'
  task removed_poms_limbo_cases: :environment do
    puts 'Report started'

    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    total = 0

    Prison.active.order(:name).each do |prison|
      poms = prison.get_list_of_poms
      removed_poms = prison.get_removed_poms(existing_poms: poms)
      next if removed_poms.empty?

      limbo_cases = removed_poms.map do |pom|
        [
          pom.allocations.sum { |a| a.allocation.primary_pom_nomis_id == pom.staff_id ? 1 : 0 },
          pom.allocations.sum { |a| a.allocation.secondary_pom_nomis_id == pom.staff_id ? 1 : 0 },
        ]
      end

      puts "==> #{prison.name}: #{limbo_cases} allocations for #{removed_poms.size} removed POMs"
      total += 1
    end

    puts "Report complete. Total prisons with deleted POMS having limbo cases: #{total} out of #{Prison.active.count}"
  end
end
