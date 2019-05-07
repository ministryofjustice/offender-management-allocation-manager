# frozen_string_literal: true

namespace :allocations do
  desc 'Copy :allocations to :allocation_versions table'
  task copy: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Allocation.all.each do |alloc|
      ActiveRecord::Base.transaction do
        alloc_version = AllocationVersion.find_by(
          nomis_offender_id: alloc.nomis_offender_id
        )

        attributes = {
          nomis_offender_id: alloc.nomis_offender_id,
          prison: alloc.prison,
          allocated_at_tier: alloc.allocated_at_tier,
          override_reasons: alloc.override_reasons,
          override_detail: alloc.override_detail,
          message: alloc.message,
          suitability_detail: alloc.suitability_detail,
          primary_pom_name: alloc.primary_pom_name,
          primary_pom_nomis_id: alloc.primary_pom_nomis_id,
          secondary_pom_name: alloc.secondary_pom_name,
          secondary_pom_nomis_id: alloc.secondary_pom_nomis_id,
          nomis_booking_id: alloc.nomis_booking_id,
          event: 0,
          event_trigger: 0
        }

        if alloc_version.nil?
          AllocationVersion.create!(attributes)
        else
          alloc_version.update!(attributes)
        end
      end
    end
  end
end
