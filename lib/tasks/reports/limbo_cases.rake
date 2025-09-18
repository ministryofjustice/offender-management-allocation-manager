# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'List all prisons having removed POMs with primary cases in limbo'
  task removed_poms_limbo_cases: :environment do
    puts 'Report started'

    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    total = 0

    Prison.active.order(:name).each do |prison|
      poms = prison.get_list_of_poms
      removed_poms = prison.get_removed_poms(existing_poms: poms)
      next if removed_poms.empty?

      limbo_cases = removed_poms.map(&:primary_allocations_count)

      puts "==> #{prison.name}: #{limbo_cases} allocations for #{removed_poms.size} removed POMs"
      total += 1
    end

    puts "Report complete. Total prisons with deleted POMS having limbo cases: #{total} out of #{Prison.active.count}"
  end
end
