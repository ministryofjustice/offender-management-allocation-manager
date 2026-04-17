# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Rolling last 12 months allocations report'
  task allocations: :environment do
    require 'csv'

    Reports::TaskLogger.configure!

    # rubocop:disable Rake/MethodDefinitionInTask
    def pom_type_at_version(allocation)
      return if allocation.recommended_pom_type.blank?

      if allocation.override_reasons.blank?
        allocation.recommended_pom_type
      else
        # the recommendation was overridden, so we flip the type
        allocation.recommended_pom_type == 'prison' ? 'probation' : 'prison'
      end
    end

    def first_allocation_known_for(allocation)
      allocation.get_old_versions.first || allocation
    end

    def first_responsibility_known_for(offender)
      if (r = offender.responsibility)
        r.versions.map(&:reify).compact.first || r
      elsif (h = offender.calculated_handover_date)
        h.versions.map(&:reify).compact.first || h
      else
        nil
      end
    end

    def log(msg)
      Reports::TaskLogger.warn('AllocationsReport', msg)
    end
    # rubocop:enable Rake/MethodDefinitionInTask

    prisons_range = Reports::TaskOptions.prisons_range
    from_date, to_date = Reports::TaskOptions.date_range
    from_date = from_date.beginning_of_day
    to_date = to_date.end_of_day

    log 'Report started'
    log "NOTE: Using range: #{prisons_range}"
    log "Date range from #{from_date} to #{to_date}."

    total = 0

    CSV.open(Reports::TaskOptions.filename('allocations.csv'), 'wb') do |csv|
      csv << %w[allocation_date prison nomis_offender_id tier CRD PRRD SLED remaining_sentence pom_type pom_responsible pom_supporting]

      Prison.active.order(name: :asc)[prisons_range].each do |prison|
        log ">> Obtaining allocations for #{prison.name} (#{prison.code})"

        AllocationHistory.where(['created_at >= ? AND created_at <= ?', from_date, to_date]).where(prison:).find_each do |allocation|
          offender = OffenderService.get_offender(
            allocation.nomis_offender_id,
            ignore_legal_status: true, fetch_complexities: false, fetch_categories: false, fetch_movements: false
          )
          next if offender.blank?

          allocation_version = first_allocation_known_for(allocation)
          responsibility = first_responsibility_known_for(offender.offender)
          pom_type = pom_type_at_version(allocation_version)

          # we only want POM responsible/supporting, not COM
          next unless responsibility && (responsibility.pom_responsible? || responsibility.pom_supporting?)

          csv << [
            allocation.created_at.to_date,
            allocation.prison,
            allocation.nomis_offender_id,
            allocation_version.allocated_at_tier,
            offender.conditional_release_date || 'n/a', # CRD
            offender.post_recall_release_date || 'n/a', # PRRD
            offender.licence_expiry_date      || 'n/a', # SLED
            offender.licence_expiry_date ? [(offender.licence_expiry_date - allocation.created_at.to_date).to_i, 0].max : 'n/a',
            pom_type || 'n/a',
            responsibility.pom_responsible?,
            responsibility.pom_supporting?,
          ]

          total += 1
          log "Total allocations so far: #{total}" if total % 200 == 0
        rescue StandardError => e
          log "Error processing #{allocation.nomis_offender_id}: #{e.message}"
        end
      end
    end

    log "Report complete. Total allocations: #{total}"
  end
end
