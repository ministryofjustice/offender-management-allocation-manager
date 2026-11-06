# frozen_string_literal: true

class BuildAllocationsController < PrisonsApplicationController
  include AllocationPomEligibility

  before_action :ensure_spo_user
  before_action :load_prisoner
  before_action :ensure_target_pom_is_eligible, :load_pom
  before_action :ensure_required_override_is_valid, only: :update

  def new
    clear_latest_allocation_details!

    # Create an empty override, which will be populated if needed
    save_to_session(override_session_key, OverrideForm.new)

    if override_needed?
      redirect_to override_prison_prisoner_staff_build_allocations_path
    else
      redirect_to allocate_prison_prisoner_staff_build_allocations_path
    end
  end

  def override
    clear_latest_allocation_details!
    @override = saved_override
  end

  def update_override
    @override = OverrideForm.new(override_params)

    if @override.valid?
      save_to_session(override_session_key, @override)
      redirect_to allocate_prison_prisoner_staff_build_allocations_path
    else
      render :override, status: :unprocessable_entity
    end
  end

  def show
    clear_latest_allocation_details!

    @allocation = AllocationForm.new
    history = allocation_history
    @event = event(history)
    @prev_pom_name = previous_pom_name(history)
    @latest_allocation_details = latest_allocation_details(history)

    render :allocate
  end

  def update
    history = allocation_history
    allocation_details = latest_allocation_details(history)

    further_info = allocation_details.slice(
      :last_oasys_completed,
      :handover_start_date,
      :handover_completion_date,
      :com_name,
      :com_email,
    )

    AllocationService.create_or_update(allocation_attributes(history), further_info)

    session.delete(override_session_key)
    store_latest_allocation_details!(allocation_details, additional_notes: allocation_params[:message])

    default_path = event(history) == :allocate_primary_pom ? unallocated_prison_prisoners_path : allocated_prison_prisoners_path
    redirect_to stored_journey_path_for(:allocation, offender_id: nomis_offender_id_from_url, default: default_path)
  end

private

  def override_session_key
    ['allocation_override', @prison.code, nomis_offender_id_from_url, staff_id].join(':')
  end

  def allocation_attributes(history)
    override = saved_override

    {
      primary_pom_nomis_id: staff_id,
      nomis_offender_id: nomis_offender_id_from_url,
      event: event(history),
      event_trigger: :user,
      created_by_username: current_user,
      allocated_at_tier: @prisoner.tier,
      allocated_at_rosh: @prisoner.rosh_level,
      recommended_pom_type: RecommendationService::POM_TYPE_LABELS.fetch(recommended_pom_type_code),
      prison: @prison.code,
      message: allocation_params[:message],
      override_reasons: override.override_reasons.presence,
      suitability_detail: override.suitability_detail,
      override_detail: override.more_detail,
    }
  end

  def override_params
    params.require(:override_form).permit(
      :more_detail,
      :suitability_detail,
      override_reasons: []
    )
  end

  def allocation_params
    params.require(:allocation_form).permit(:message)
  end

  def load_prisoner
    @prisoner = get_offender_or_404(nomis_offender_id_from_url)
  end

  def load_pom
    @pom = StaffMember.new(@prison, staff_id)
  end

  def saved_override
    @saved_override ||= OverrideForm.new(session[override_session_key])
  end

  def ensure_required_override_is_valid
    return unless override_needed?
    return if saved_override.valid?

    clear_latest_allocation_details!

    audit(failure: HmppsAuditing::VALIDATION_FAILED)
    redirect_to override_prison_prisoner_staff_build_allocations_path
  end

  def ensure_target_pom_is_eligible
    return if eligible_pom_ids.include?(staff_id)

    clear_latest_allocation_details!
    session.delete(override_session_key)

    redirect_to prison_prisoner_staff_index_path(@prison.code, nomis_offender_id_from_url),
                alert: 'Choose a POM from the available list to allocate this case.'
  end

  def nomis_offender_id_from_url
    params.require(:prisoner_id)
  end

  def staff_id
    params.require(:staff_id).to_i
  end

  def override_needed?
    recommended_pom_type_code == RecommendationService::PRISON_POM && @pom.probation_officer? ||
      recommended_pom_type_code == RecommendationService::PROBATION_POM && @pom.prison_officer? ||
      recommended_pom_type_code == RecommendationService::NO_RECOMMENDATION
  end

  def recommended_pom_type_code
    @recommended_pom_type_code ||= RecommendationService.recommended_pom_type(@prisoner)
  end

  def allocation_history
    @allocation_history ||= AllocationHistory.find_by(prison: @prison.code, nomis_offender_id: nomis_offender_id_from_url)
  end

  def eligible_pom_ids
    eligible_allocation_poms(@prison.get_list_of_poms, allocation_history).map(&:staff_id)
  end

  def event(history)
    @event ||= history&.active? ? :reallocate_primary_pom : :allocate_primary_pom
  end

  def latest_allocation_details(history)
    build_latest_allocation_details(
      offender: @prisoner,
      pom: @pom,
      prev_pom_name: previous_pom_name(history)
    )
  end

  def previous_pom_name(history)
    return nil unless history&.primary_pom_nomis_id

    StaffMember.new(@prison, history.primary_pom_nomis_id).full_name_ordered
  end
end
