# frozen_string_literal: true

class FemaleAllocationsController < PrisonsApplicationController
  before_action :load_pom_types, only: :index
  before_action :load_prisoner

  include Wicked::Wizard

  steps :override, :allocate

  def index
    @case_info = CaseInformation.find_by!(nomis_offender_id: nomis_offender_id_from_url)
    previous_allocation = Allocation.find_by nomis_offender_id: nomis_offender_id_from_url
    previous_pom_ids = if previous_allocation
                         previous_allocation.previously_allocated_poms
                       else
                         []
                       end
    poms = PrisonOffenderManagerService.get_poms_for(active_prison_id).index_by(&:staff_id)
    @previous_poms = previous_pom_ids.map { |staff_id| poms[staff_id] }.compact
    @current_pom = PrisonOffenderManagerService.get_pom_at(active_prison_id, previous_allocation.primary_pom_nomis_id) if previous_allocation&.primary_pom_nomis_id
  end

  def new
    pom = StaffMember.new(@prison, staff_id)

    # Create an empty override, which will be populated if needed
    save_to_session :female_allocation_override, Override.new

    # If the recommendation is different to the allocation, then go the full journey via override, otherwise jump straight to allocation
    if RecommendationService::recommended_pom_type(@prisoner) == RecommendationService::PRISON_POM && pom.probation_officer? ||
      RecommendationService::recommended_pom_type(@prisoner) == RecommendationService::PROBATION_POM && pom.prison_officer?
      redirect_to wizard_path(steps.first)
    else
      # Override isn't needed – go straight to the allocate step
      redirect_to wizard_path(:allocate)
    end
  end

  def show
    @pom = StaffMember.new(@prison, staff_id)
    @override = Override.new session[:female_allocation_override]
    @allocation = AllocationForm.new
    render_wizard
  end

  def update
    if step == :override
      @override = Override.new override_params.merge(nomis_staff_id: staff_id, nomis_offender_id: nomis_offender_id_from_url)
      if @override.valid?
        save_to_session :female_allocation_override, @override
        redirect_to next_wizard_path
      else
        render_wizard
      end
    else
      override = Override.new session[:female_allocation_override]
      event = if Allocation.find_by(prison: @prison.code, nomis_offender_id: nomis_offender_id_from_url)&.active?
                :reallocate_primary_pom
              else
                :allocate_primary_pom
              end

      allocation_attributes =
        {
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: nomis_offender_id_from_url,
          event: event,
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

      AllocationService.create_or_update(allocation_attributes)
      session.delete :female_allocation_override

      redirect_to unallocated_prison_prisoners_path(active_prison_id)
    end
  end

private

  def override_params
    params.require(:override).permit(
      :more_detail,
      :suitability_detail,
      override_reasons: []
    )
  end

  def allocation_params
    params.require(:allocation_form).permit(:message)
  end

  def load_pom_types
    poms = PrisonOffenderManagerService.get_poms_for(active_prison_id).map { |pom| StaffMember.new(@prison, pom.staff_id) }
    @probation_poms, @prison_poms = poms.partition(&:probation_officer?)
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
end
