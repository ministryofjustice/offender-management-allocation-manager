# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report listing the LDU and Tier for all POM responsible cases'
  task ldu_and_tiers: :environment do
    require 'csv'

    # Examples: 0.. | 0..60 | 61..
    prisons_range = ENV.fetch('PRISONS_RANGE', '0').split('..').map(&:to_i)
    prisons_range = Range.new(prisons_range[0], prisons_range[1])

    ldu_and_tiers prisons_range

    puts 'Report complete'
  end
end

def ldu_and_tiers(prisons_range, show_header: true)
  CSV.open('ldu_and_tiers.csv', 'wb') do |csv|
    csv << %w[nomis_id ldu sentence_type tier] if show_header

    Prison.active.order(name: :asc)[prisons_range].each do |prison|
      puts "Processing #{prison.code}"

      prison.offenders.each do |offender|
        next unless offender.pom_responsible?

        sentence_type = if offender.indeterminate_sentence?
                          'ISP'
                        elsif offender.parole_eligibility_date.present?
                          'EDS'
                        else
                          'SD'
                        end

        csv << [offender.offender_no, offender.ldu_name, sentence_type, offender.tier]
      end
    end
    # the large array above can often kill the bash connection so just set the return as nil
    nil
  end
end
