# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Rolling last 12 months CSV report listing handover dates'
  task handover_dates: :environment do
    require 'csv'

    # rubocop:disable Rake/MethodDefinitionInTask
    def log(msg)
      Reports::TaskLogger.warn('HandoversReport', msg)
    end

    def handover_type(offender)
      enhanced_resourcing = offender.case_information.try(:enhanced_resourcing)
      return 'missing' if enhanced_resourcing.nil?

      enhanced_resourcing ? 'enhanced' : 'standard'
    end
    # rubocop:enable Rake/MethodDefinitionInTask

    Reports::TaskLogger.configure!

    prisons_range = Reports::TaskOptions.prisons_range
    from_date, to_date = Reports::TaskOptions.date_range
    from_date = from_date.beginning_of_day
    to_date = to_date.end_of_day

    log 'Report started'
    log "NOTE: Using range: #{prisons_range}"
    log "Date range from #{from_date} to #{to_date}."

    total = 0

    timeframe = [
      'handover_date >= ? AND handover_date <= ?', from_date, to_date
    ].freeze

    CSV.open(Reports::TaskOptions.filename('handovers.csv'), 'wb') do |csv|
      csv << %w[prison nomis_offender_id ldu_code ldu_name handover_date CRD PED TED handover_type]

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
            handover_type(offender),
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
