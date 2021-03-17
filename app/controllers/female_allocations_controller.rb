# frozen_string_literal: true

class FemaleAllocationsController < PrisonsApplicationController
  before_action :load_pom_types_and_prisoner

  def new
    @case_info = CaseInformation.find_by!(nomis_offender_id: nomis_offender_id_from_url)
    previous_allocation = Allocation.find_by nomis_offender_id: nomis_offender_id_from_url
    previous_pom_ids = if previous_allocation
                         previous_allocation.history.map { |h| [h.primary_pom_nomis_id, h.secondary_pom_nomis_id] }.flatten.compact.uniq
                       else
                         []
                       end
    poms = PrisonOffenderManagerService.get_poms_for(active_prison_id).index_by(&:staff_id)
    @previous_poms = previous_pom_ids.map { |staff_id| poms[staff_id] }.compact
  end

  def override
    staff_id = params.require(:id).to_i
    @pom = StaffMember.new(@prison, staff_id)
    @override = Override.new nomis_staff_id: staff_id, nomis_offender_id: nomis_offender_id_from_url
  end

  def save_override
    staff_id = params.require(:id).to_i
    @pom = StaffMember.new(@prison, staff_id)
    @allocation = AllocationForm.new

    @override = Override.new override_params.merge(nomis_staff_id: staff_id, nomis_offender_id: nomis_offender_id_from_url)
    if @override.valid?
      session[:female_allocation_override] = @override
      render 'allocate'
    else
      render 'override'
    end
  end

  def allocate
    @prisoner = OffenderService.get_offender(nomis_offender_id_from_url)
    staff_id = params.require(:id).to_i
    @pom = StaffMember.new(@prison, staff_id)
    @allocation = AllocationForm.new

    # create an empty override for the simple case
    session[:female_allocation_override] = Override.new
  end

  def confirm
    override = Override.new session[:female_allocation_override]

    allocation_attributes =
      {
        primary_pom_nomis_id: params[:id].to_i,
        nomis_offender_id: nomis_offender_id_from_url,
        event: :allocate_primary_pom,
        event_trigger: :user,
        created_by_username: current_user,
        nomis_booking_id: @prisoner.booking_id,
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

  def load_pom_types_and_prisoner
    poms = PrisonOffenderManagerService.get_poms_for(active_prison_id).map { |pom| StaffMember.new(@prison, pom.staff_id) }
    @probation_poms, @prison_poms = poms.partition(&:probation_officer?)
    @prisoner = OffenderService.get_offender(nomis_offender_id_from_url)
  end

  def nomis_offender_id_from_url
    params.require(:prisoner_id)
  end
end
