class AllocationsController < ApplicationController
  before_action :authenticate_user

  def new
    @prisoner = prisoner(nomis_offender_id_from_url)
    @previously_allocated_pom_ids =
      AllocationService.previously_allocated_poms(nomis_offender_id_from_url)
    @recommended_poms, @not_recommended_poms =
      recommended_and_nonrecommended_poms_for(@prisoner)
  end

  def edit
    @prisoner = prisoner(nomis_offender_id_from_url)
    @previously_allocated_pom_ids =
      AllocationService.previously_allocated_poms(nomis_offender_id_from_url)
    @recommended_poms, @not_recommended_poms =
      recommended_and_nonrecommended_poms_for(@prisoner)
    @current_pom = current_pom_for(nomis_offender_id_from_url)
  end

  def confirm
    @prisoner = prisoner(nomis_offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(active_caseload, nomis_staff_id_from_url)
  end

  # rubocop:disable Metrics/MethodLength
  def create
    prisoner  = prisoner(allocation_params[:nomis_offender_id])
    @override = override

    AllocationService.create_allocation(
      nomis_staff_id: allocation_params[:nomis_staff_id].to_i,
      nomis_offender_id: allocation_params[:nomis_offender_id],
      created_by: current_user,
      nomis_booking_id: prisoner.latest_booking_id,
      allocated_at_tier: prisoner.tier,
      prison: active_caseload,
      override_reasons: override_reasons,
      override_detail: override_detail,
      responsibility: ResponsibilityService.calculate_pom_responsibility(prisoner),
      message: allocation_params[:message]
    )

    redirect_to summary_unallocated_path
  end
# rubocop:enable Metrics/MethodLength

private

  def prisoner(nomis_offender_id)
    OffenderService.get_offender(nomis_offender_id)
  end

  def override
    Override.where(
      nomis_offender_id: allocation_params[:nomis_offender_id]).
      where(nomis_staff_id: allocation_params[:nomis_staff_id]).last
  end

  def current_pom_for(nomis_offender_id)
    current_allocation = AllocationService.active_allocations(nomis_offender_id)
    nomis_staff_id = current_allocation[nomis_offender_id]['nomis_staff_id']

    PrisonOffenderManagerService.get_pom(active_caseload, nomis_staff_id)
  end

  def recommended_and_nonrecommended_poms_for(prisoner)
    pom_response = PrisonOffenderManagerService.get_poms(active_caseload) { |pom|
      pom.status == 'active'
    }

    pom_response.partition { |pom|
      pom.position_description.include?(prisoner.case_owner)
    }
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def nomis_staff_id_from_url
    params.require(:nomis_staff_id)
  end

  def allocation_params
    params.require(:allocations).permit(:nomis_staff_id, :nomis_offender_id, :message)
  end

  def override_reasons
    @override[:override_reasons] if @override.present?
  end

  def override_detail
    @override[:more_detail] if @override.present?
  end
end
