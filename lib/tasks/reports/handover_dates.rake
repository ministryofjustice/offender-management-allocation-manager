# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Rolling last 12 months CSV report listing handover dates'
  task handover_dates: :environment do
    require 'csv'

    # rubocop:disable Rake/MethodDefinitionInTask
    def log(msg)
      Rails.logger.warn("#{Time.current.strftime('%Y-%m-%d %H:%M:%S.%3N')} [HandoversReport] #{msg}")
    end
    # rubocop:enable Rake/MethodDefinitionInTask

    $stdout.sync = true
    Rails.logger = Logger.new($stdout)

    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    # Examples: 0.. | 0..60 | 61..
    prisons_range = ENV.fetch('PRISONS_RANGE', '0').split('..').map(&:to_i)
    prisons_range = Range.new(prisons_range[0], prisons_range[1])

    log 'Report started'
    log "NOTE: Using range: #{prisons_range}"

    total = 0

    timeframe = [
      'handover_date >= ? AND handover_date <= ?',
      1.year.ago.at_beginning_of_day,
      Date.current.end_of_day
    ].freeze

    CSV.open(ENV.fetch('FILENAME', 'handovers.csv'), 'wb') do |csv|
      csv << %w[prison nomis_offender_id ldu_code ldu_name handover_date CRD PED TED]

      Prison.active.order(code: :asc)[prisons_range].each do |prison|
        log ">> Obtaining handovers for #{prison.name} (#{prison.code})"

        eligible_offender_ids = OmicEligibility.where(eligible: true, prison: prison.code).pluck(:nomis_offender_id)
        handovers = CalculatedHandoverDate.where(timeframe).where(nomis_offender_id: eligible_offender_ids)

        offenders = OffenderService.get_offenders(
          handovers.pluck(:nomis_offender_id),
          ignore_legal_status: true, fetch_complexities: false, fetch_categories: false, fetch_movements: false
        )

        offenders.each do |offender|
          next unless offender.conditional_release_date || offender.parole_eligibility_date || offender.tariff_date

          csv << [
            prison.code,
            offender.offender_no,
            offender.case_information&.ldu_code || 'n/a',
            offender.case_information&.local_delivery_unit&.name || 'n/a',
            offender.handover_date,
            offender.conditional_release_date, # CRD
            offender.parole_eligibility_date,  # PED
            offender.tariff_date,              # TED
          ]

          total += 1
          log "Total handovers so far: #{total}" if total % 100 == 0
        rescue StandardError => e
          log "Error processing #{offender.offender_no}: #{e.message}"
        end
      end
    end

    log 'Report complete'
  end
end
