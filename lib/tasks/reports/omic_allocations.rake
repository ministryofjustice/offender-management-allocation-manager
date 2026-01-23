# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Rolling last 12 months allocations report'
  task allocations: :environment do
    require 'csv'

    # rubocop:disable Rake/MethodDefinitionInTask
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
    # rubocop:enable Rake/MethodDefinitionInTask

    puts 'Report started'

    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    total = 0

    CSV.open('allocations.csv', 'wb') do |csv|
      csv << %w[allocation_date nomis_offender_id tier CRD remaining_sentence sentence_duration pom_responsible pom_supporting com_responsible com_supporting]

      AllocationHistory.where(['created_at >= ?', 1.year.ago]).find_each do |allocation|
        offender = OffenderService.get_offender(allocation.nomis_offender_id)
        next if offender.blank?

        allocation_version = first_allocation_known_for(allocation)
        responsibility = first_responsibility_known_for(offender.offender)

        csv << [
          allocation.created_at,
          allocation.nomis_offender_id,
          allocation_version.allocated_at_tier,
          offender.conditional_release_date || 'n/a',
          offender.conditional_release_date ? (offender.conditional_release_date - Time.zone.today).to_i : 'n/a',
          offender.sentences.duration.in_days.round,
          responsibility ? responsibility.pom_responsible? : 'n/a',
          responsibility ? responsibility.pom_supporting?  : 'n/a',
          responsibility ? responsibility.com_responsible? : 'n/a',
          responsibility ? responsibility.com_supporting?  : 'n/a',
        ]

        total += 1
        puts "Processed so far: #{total}" if total % 100 == 0
      rescue StandardError => e
        puts "Error processing #{allocation.nomis_offender_id}: #{e.message}"
      end
    end

    puts "Report complete. Total allocations: #{total}"
  end
end
