# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report listing all cases handover type (enhanced or standard)'
  task handover_type: :environment do
    require 'csv'

    # Examples: 0.. | 0..60 | 61..
    prisons_range = ENV.fetch('PRISONS_RANGE', '0').split('..').map(&:to_i)
    prisons_range = Range.new(prisons_range[0], prisons_range[1])

    puts "NOTE: Using range: #{prisons_range}"

    CSV.open('handover_type.csv', 'wb') do |csv|
      csv << %w[nomis_id handover_type]

      Prison.active.order(name: :asc)[prisons_range].each do |prison|
        puts ">> Obtaining cases for #{prison.name} (#{prison.code})"

        prison.primary_allocated_offenders.each do |offender|
          csv << [
            offender.offender_no,
            offender.enhanced_handover? ? 'enhanced' : 'standard',
          ]
        end
      end
    end

    puts 'Report complete'
  end
end
