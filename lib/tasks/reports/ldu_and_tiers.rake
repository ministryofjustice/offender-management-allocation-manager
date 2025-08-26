# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report listing the LDU and Tier for all POM responsible cases'
  task ldu_and_tiers: :environment do
    require 'csv'

    # Examples: 0.. | 0..60 | 61..
    prisons_range = ENV.fetch('PRISONS_RANGE', '0').split('..').map(&:to_i)
    prisons_range = Range.new(prisons_range[0], prisons_range[1])

    CSV.open('ldu_and_tiers.csv', 'wb') do |csv|
      csv << %w[nomis_id ldu tier prison]

      Prison.active.order(name: :asc)[prisons_range].each do |prison|
        puts "Processing #{prison.code}"

        prison.offenders.each do |offender|
          next unless offender.pom_responsible?

          csv << [offender.offender_no, offender.ldu_name, offender.tier, prison.code]
        end
      end
    end

    puts 'Report complete'
  end
end
