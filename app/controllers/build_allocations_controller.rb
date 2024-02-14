# frozen_string_literal: true

class BuildAllocationsController < PrisonsApplicationController
  before_action :ensure_spo_user
  before_action :load_prisoner
  before_action :set_referrer

  include Wicked::Wizard
  include OffenderHelper

  steps :override, :allocate

  def new
    pom = StaffMember.new(@prison, staff_id)

    # Create an empty override, which will be populated if needed
    save_to_session :female_allocation_override, OverrideForm.new

    # If the recommendation is different to the allocation, then go the full journey via override, otherwise jump straight to allocation
    if RecommendationService.recommended_pom_type(@prisoner) == RecommendationService::PRISON_POM && pom.probation_officer? ||
      RecommendationService.recommended_pom_type(@prisoner) == RecommendationService::PROBATION_POM && pom.prison_officer?
      redirect_to wizard_path(steps.first)
    else
      # Override isn't needed – go straight to the allocate step
      redirect_to wizard_path(:allocate)
    end
  end

  def show
    @pom = StaffMember.new(@prison, staff_id)
    @override = OverrideForm.new session[:female_allocation_override]
    @allocation = AllocationForm.new
    history = AllocationHistory.find_by(prison: @prison.code, nomis_offender_id: nomis_offender_id_from_url)
    @reallocating_same_pom = event(history) == :reallocate_primary_pom && staff_id == history.primary_pom_nomis_id

    unless @reallocating_same_pom
      @prev_pom_name = history&.primary_pom_nomis_id ? view_context.full_name_ordered(StaffMember.new(@prison, history.primary_pom_nomis_id)) : nil
      @latest_allocation_details = session[:latest_allocation_details] = format_allocation(
        offender: @prisoner, pom: @pom, prev_pom_name: @prev_pom_name, view_context: view_context)
    end

    render_wizard
  end

  def update
    if step == :override
      @override = OverrideForm.new override_params
      if @override.valid?
        save_to_session :female_allocation_override, @override
        redirect_to next_wizard_path
      else
        render_wizard
      end
    else
      history = AllocationHistory.find_by(prison: @prison.code, nomis_offender_id: nomis_offender_id_from_url)
      reallocating_same_pom = event(history) == :reallocate_primary_pom && staff_id == history.primary_pom_nomis_id

      if reallocating_same_pom
        pom = StaffMember.new(@prison, staff_id)
        flash[:notice] = "#{@prisoner.full_name_ordered} allocated to #{view_context.full_name_ordered(pom)}"
      else
        override = OverrideForm.new session[:female_allocation_override]

        allocation_attributes = {
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: nomis_offender_id_from_url,
          event: event(history),
          event_trigger: :user,
          created_by_username: current_user,
          allocated_at_tier: @prisoner.tier,
          recommended_pom_type: (RecommendationService.recommended_pom_type(@prisoner) == RecommendationService::PRISON_POM) ? 'prison' : 'probation',
          prison: active_prison_id,
          message: allocation_params[:message],
          override_reasons: override.override_reasons,
          suitability_detail: override.suitability_detail,
          override_detail: override.more_detail,
        }

        further_info = session[:latest_allocation_details].slice(
          :last_oasys_completed,
          :handover_start_date,
          :handover_completion_date,
          :com_name,
          :com_email
        )

        AllocationService.create_or_update(allocation_attributes, further_info)
        session.delete :female_allocation_override
        session[:latest_allocation_details][:additional_notes] = allocation_params[:message]
      end

      redirect_to (event(history) == :allocate_primary_pom) ? unallocated_prison_prisoners_path : allocated_prison_prisoners_path
    end
  end

private

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
    @prisoner = OffenderService.get_offender(nomis_offender_id_from_url)
  end

  def nomis_offender_id_from_url
    params.require(:prisoner_id)
  end

  def staff_id
    params.require(:staff_id).to_i
  end

  def event(history)
    @event ||= history&.active? ? :reallocate_primary_pom : :allocate_primary_pom
  end
end
