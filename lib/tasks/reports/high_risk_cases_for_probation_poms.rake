# frozen_string_literal: true

require 'rake'
require 'csv'

namespace :reports do
  desc 'Create a CSV report listing counds of allocated tier A & B by prison code'
  task high_risk_cases_for_probation_poms: :environment do
    CSV.open('high_risk_cases_for_probation_poms.csv', 'wb') do |csv|
      csv << %w[prison total]

      grand_total = 0

      Prison.active.order(name: :asc).each do |prison|
        puts ">> Obtaining cases for #{prison.name} (#{prison.code})"

        total = prison.primary_allocated_offenders.select { it.tier.in?(['A', 'B']) && it.high_rosh_level? }
        grand_total += total

        csv << [prison.code, total]
      end

      csv << ['Total', grand_total]
    end

    puts 'Report complete'
  end
end
