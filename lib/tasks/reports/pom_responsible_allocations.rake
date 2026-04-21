# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report for currently valid allocations where the POM is responsible'
  task pom_responsible_allocations: :environment do
    require 'csv'

    Reports::TaskLogger.configure!

    # rubocop:disable Rake/MethodDefinitionInTask
    def log(msg)
      Reports::TaskLogger.warn('PomResponsibleAllocationsReport', msg)
    end

    def csv_headers
      [
        'Allocation Date',
        'Establishment',
        'NOMIS Offender ID',
        'CRD',
        'Tier',
        'RoSH',
        'SED/SLED',
        'Sentence Remaining',
        'Current POM Responsible',
        'Current POM ID',
        'Current POM Name'
      ].freeze
    end

    def format_date(value)
      value&.to_date&.iso8601
    end

    def allocation_date_for(offender)
      offender[:allocation].primary_pom_allocated_at&.to_date || offender[:allocation].updated_at&.to_date
    end

    def pom_types_by_id(prison)
      prison.get_list_of_poms.each_with_object({}) do |pom, types|
        types[pom.staff_id] = if pom.probation_officer?
                                'probation'
                              elsif pom.prison_officer?
                                'prison'
                              end
      end
    rescue StandardError => e
      log "Unable to load live POM types for #{prison.code}: #{e.message}"
      {}
    end

    def eligible_nomis_ids_for(prison, offenders)
      OmicEligibility.eligible
        .where(prison: prison.code, nomis_offender_id: offenders.map(&:offender_no))
        .pluck(:nomis_offender_id)
        .to_set
    end

    def calculated_handover_dates_by_id(offenders)
      CalculatedHandoverDate.where(nomis_offender_id: offenders.map(&:offender_no)).index_by(&:nomis_offender_id)
    end

    def current_responsibility_for(offender, calculated_handover_date)
      offender.offender.responsibility ||
        calculated_handover_date ||
        HandoverDateService.handover(offender)
    end

    def allocated_offenders_for(prison)
      offenders = OffenderService.get_offenders_in_prison(
        prison, fetch_complexities: false, fetch_categories: false, fetch_movements: false
      )

      calculated_handover_dates = calculated_handover_dates_by_id(offenders)
      eligible_nomis_ids = eligible_nomis_ids_for(prison, offenders)

      active_allocations_by_id = AllocationHistory.active_allocations_for_prison(prison.code)
        .where(nomis_offender_id: eligible_nomis_ids.to_a)
        .index_by(&:nomis_offender_id)

      offenders.filter_map do |offender|
        next unless eligible_nomis_ids.include?(offender.offender_no)
        next unless active_allocations_by_id.key?(offender.offender_no)

        {
          offender: offender,
          allocation: active_allocations_by_id.fetch(offender.offender_no),
          calculated_handover_date: calculated_handover_dates[offender.offender_no]
        }
      end
    end

    def sentence_remaining_for(offender)
      allocation_date = allocation_date_for(offender)
      sentence_end_date = offender[:offender].licence_expiry_date
      return if allocation_date.blank? || sentence_end_date.blank?

      [(sentence_end_date - allocation_date).to_i, 0].max
    end

    def reportable_rows_for(prison, from_date:, to_date:)
      pom_types = pom_types_by_id(prison)

      allocated_offenders_for(prison).filter_map do |offender|
        responsibility = current_responsibility_for(offender[:offender], offender[:calculated_handover_date])
        next unless responsibility&.pom_responsible?

        allocation_date = allocation_date_for(offender)
        next if allocation_date.blank? || allocation_date < from_date || allocation_date > to_date

        case_information = offender[:offender].case_information
        allocation = offender[:allocation]

        [
          format_date(allocation_date),
          prison.code,
          offender[:offender].offender_no,
          format_date(offender[:offender].conditional_release_date),
          case_information.tier,
          case_information.rosh_level.presence,
          format_date(offender[:offender].licence_expiry_date),
          sentence_remaining_for(offender),
          pom_types[allocation.primary_pom_nomis_id],
          allocation.primary_pom_nomis_id,
          allocation.formatted_primary_pom_name,
        ]
      end
    end
    # rubocop:enable Rake/MethodDefinitionInTask

    prisons_range = Reports::TaskOptions.prisons_range
    from_date, to_date = Reports::TaskOptions.date_range

    log 'Report started'
    log "NOTE: Using range: #{prisons_range}"
    log "Allocation date range from #{from_date} to #{to_date}."

    total = 0
    prisons = Prison.active.order(code: :asc).to_a[prisons_range] || []

    CSV.open(Reports::TaskOptions.filename('pom_responsible_allocations.csv'), 'wb') do |csv|
      csv << csv_headers

      prisons.each do |prison|
        log ">> Obtaining current responsible allocations for #{prison.name} (#{prison.code})"

        prison_total = 0

        reportable_rows_for(prison, from_date:, to_date:).each do |row|
          csv << row
          prison_total += 1
          total += 1
          log "Total rows so far: #{total}" if total % 200 == 0
        end

        log "Completed #{prison.code}: #{prison_total} rows"
      rescue StandardError => e
        log "Error processing prison #{prison.code}: #{e.message}"
      end
    end

    log "Report complete. Total rows: #{total}"
  end
end
