# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report listing all cases handover type (enhanced or standard)'
  task handover_type: :environment do
    require 'csv'

    prisons_range = Reports::TaskOptions.prisons_range

    puts "NOTE: Using range: #{prisons_range}"

    CSV.open(Reports::TaskOptions.filename('handover_type.csv'), 'wb') do |csv|
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
