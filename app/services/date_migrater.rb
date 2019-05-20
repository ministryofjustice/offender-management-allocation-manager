# frozen_string_literal: true

class DateMigrater
  def self.run
    Allocation.where(active: true).each do |alloc|
      alloc_version = AllocationVersion.find_by(nomis_offender_id: alloc.nomis_offender_id)

      alloc_version&.update!(primary_pom_allocated_at: alloc.created_at)
    end
  end
end
