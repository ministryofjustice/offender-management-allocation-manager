# frozen_string_literal: true

require 'rake'
require 'csv'

namespace :reports do
  desc 'Create a CSV report listing counds of allocated tier A & B by prison code'
  task high_risk_cases_for_probation_poms: :environment do
    CSV.open('high_risk_cases_for_probation_poms.csv', 'wb') do |csv|
      csv << %w[prison total_supporting total_responsible total]

      total_supporting = 0
      total_responsible = 0
      grand_total = 0

      Prison.active.order(name: :asc).each do |prison|
        puts ">> Obtaining cases for #{prison.name} (#{prison.code})"

        allocated_high_risk_offenders = prison
          .primary_allocated_offenders
          .select { it.tier.in?(['A', 'B']) && it.high_rosh_level? }

        supporting = allocated_high_risk_offenders.select(&:pom_supporting?).count
        responsible = allocated_high_risk_offenders.select(&:pom_responsible?).count
        total = supporting + responsible

        csv << ["#{prison.code} - #{prison.name}", supporting, responsible, total]

        total_supporting += supporting
        total_responsible += responsible
        grand_total += total
      end

      csv << ['Total', total_supporting, total_responsible, grand_total]
    end

    puts 'Report complete'
  end
end
