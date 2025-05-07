# frozen_string_literal: true

class CaseHistory
  delegate :primary_pom_nomis_id, :event_trigger, :secondary_pom_nomis_id,
           :allocated_at_tier, :nomis_offender_id, :primary_pom_name, :override_reasons, :suitability_detail,
           :override_detail,
           :recommended_pom_type, :secondary_pom_name, to: :@allocation

  def initialize(prev_allocation, allocation, version)
    @previous_allocation = prev_allocation
    @allocation = allocation
    @version = version
  end

  def system_admin_name
    @version.whodunnit
  end

  # rubocop:disable Rails/Delegate
  def system_admin_note
    @version.system_admin_note
  end
  # rubocop:enable Rails/Delegate

  # we need to override the 'updated_at' in the history with the 'to' value (index 1)
  # so that if it is changed later w/o history (e.g. by updating the COM name)
  # we don't produce the wrong answer
  # This is now 'created_at' to reflect that this is the 'created time' of the history record
  # and the 'updated_at' does not exist (because history records cannot be modified)
  # The diff is of course stored in UTC, so we have to convert to local time
  # manually as we've bypassed the library code in this instance
  def created_at
    YAML.unsafe_load(@version.object_changes).fetch('updated_at').second.getlocal
  end

  # If we have a 'first' reallocation for a prison then show it as an allocation because it is -
  # the incorrect data caused by a defect is too hard to change as it is YAML
  def event
    if @allocation.event == 'reallocate_primary_pom' && @previous_allocation.prison != @allocation.prison
      'allocate_primary_pom'
    else
      @allocation.event
    end
  end

  # don't allow auto-deallocations to say that a person did it
  def created_by_name
    if @allocation.event_trigger == 'user'
      @allocation.created_by_name
    elsif system_admin_note && system_admin_name
      "System Admin (#{system_admin_name})"
    end
  end

  # TODO: - this isn't great fetching emails in the view/presenter layer. However this is better than what came
  # before (which was to expose the id and let the view work it out via a hash of emails collected using the API)
  # Hopefully soon the model will answer these questions properly
  def primary_pom_email
    @primary_pom_email ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@allocation.primary_pom_nomis_id).first
  end

  def secondary_pom_email
    @secondary_pom_email ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@allocation.secondary_pom_nomis_id).first
  end

  def previous_primary_pom_email
    @previous_primary_pom_email ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@previous_allocation.primary_pom_nomis_id).first
  end

  def previous_secondary_pom_email
    @previous_secondary_pom_email ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@previous_allocation.secondary_pom_nomis_id).first
  end

  def previous_primary_pom_name
    @previous_allocation.primary_pom_name
  end

  def previous_secondary_pom_name
    @previous_allocation.secondary_pom_name
  end

  # render a different partial depending on the type of event
  def to_partial_path
    "case_history/allocation/#{event}"
  end
end
