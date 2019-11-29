# frozen_string_literal: true

class AllocationPresenter
  delegate :primary_pom_nomis_id, :event, :event_trigger, :secondary_pom_nomis_id, :prison,
           :allocated_at_tier, :nomis_offender_id, :primary_pom_name, :override_reasons, :suitability_detail,
           :created_by_name, :nomis_booking_id, :recommended_pom_type, :secondary_pom_name, to: :@allocation

  def initialize(allocation, version)
    @allocation = allocation
    @version = version
  end

  # we need to override the 'updated_at' in the history with the 'to' value (index 1)
  # so that if it is changed later w/o history (e.g. by updating the COM name)
  # we don't produce the wrong answer
  def updated_at
    YAML.load(@version.object_changes).fetch('updated_at')[1]
  end
end
