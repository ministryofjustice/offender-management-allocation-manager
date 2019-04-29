# frozen_string_literal: true

class AllocationsController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Allocated', :summary_allocated, only: [:show]
  breadcrumb -> { offender(nomis_offender_id_from_url).full_name },
    -> { allocation_path(nomis_offender_id_from_url) }, only: [:show]

  def new
    @prisoner = offender(nomis_offender_id_from_url)
    @previously_allocated_pom_ids =
      AllocationService.previously_allocated_poms(nomis_offender_id_from_url)
    @recommended_poms, @not_recommended_poms =
      recommended_and_nonrecommended_poms_for(@prisoner)
    @recommended_pom_type, @not_recommended_pom_type =
      recommended_and_nonrecommended_poms_types_for(@prisoner)
  end

  # rubocop:disable Metrics/LineLength
  def show
    @prisoner = offender(nomis_offender_id_from_url)
    primary_pom_nomis_id = AllocationService.primary_pom_nomis_id(@prisoner.offender_no)
    @pom = PrisonOffenderManagerService.get_pom(active_caseload, primary_pom_nomis_id)
    @keyworker = Nomis::Keyworker::KeyworkerApi.get_keyworker(active_caseload, @prisoner.offender_no)
    @history = AllocationService.offender_allocation_history(@prisoner.offender_no)
  end
  # rubocop:enable Metrics/LineLength

  # rubocop:disable Metrics/MethodLength
  def edit
    unless AllocationService.active_allocation?(nomis_offender_id_from_url)
      redirect_to new_allocation_path(nomis_offender_id_from_url)
      return
    end

    @prisoner = offender(nomis_offender_id_from_url)
    @previously_allocated_pom_ids =
      AllocationService.previously_allocated_poms(nomis_offender_id_from_url)
    @recommended_poms, @not_recommended_poms =
      recommended_and_nonrecommended_poms_for(@prisoner)
    @recommended_pom_type, @not_recommended_pom_type =
      recommended_and_nonrecommended_poms_types_for(@prisoner)
    @current_pom = current_pom_for(nomis_offender_id_from_url)
  end
  # rubocop:enable Metrics/MethodLength

  def confirm
    @prisoner = offender(nomis_offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(
      active_caseload,
      nomis_staff_id_from_url
    )
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/LineLength
  def create
    offender = offender(allocation_params[:nomis_offender_id])
    pom = PrisonOffenderManagerService.get_pom(
      active_caseload,
      allocation_params[:nomis_staff_id]
    )

    @override = override
    allocation = {
      primary_pom_nomis_id: allocation_params[:nomis_staff_id].to_i,
      nomis_offender_id: allocation_params[:nomis_offender_id],
      created_by_username: current_user,
      nomis_booking_id: offender.latest_booking_id,
      allocated_at_tier: offender.tier,
      prison: active_caseload,
      override_reasons: override_reasons,
      suitability_detail: suitability_detail,
      override_detail: override_detail,
      message: allocation_params[:message]
    }

    if AllocationService.create_allocation allocation
      flash[:notice] = "#{offender.full_name_ordered} has been allocated to #{pom.full_name_ordered} (#{pom.grade})"
    else
      flash[:alert] = "#{offender.full_name_ordered} has not been allocated  - please try again"
    end

    redirect_to summary_unallocated_path
  end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/LineLength

private

  def offender(nomis_offender_id)
    OffenderService.get_offender(nomis_offender_id)
  end

  def override
    Override.where(
      nomis_offender_id: allocation_params[:nomis_offender_id]).
      where(nomis_staff_id: allocation_params[:nomis_staff_id]).last
  end

  def current_pom_for(nomis_offender_id)
    current_allocation = AllocationService.active_allocations(nomis_offender_id)
    nomis_staff_id = current_allocation[nomis_offender_id]['primary_pom_nomis_id']

    PrisonOffenderManagerService.get_pom(active_caseload, nomis_staff_id)
  end

  def recommended_and_nonrecommended_poms_types_for(offender)
    rec_type = RecommendationService.recommended_pom_type(offender)

    if rec_type == RecommendationService::PRISON_POM
      ['Prison officer',
       'Probation officer']
    else
      ['Probation officer',
       'Prison officer']
    end
  end

  def recommended_and_nonrecommended_poms_for(offender)
    poms = PrisonOffenderManagerService.get_poms(active_caseload) { |pom|
      pom.status == 'active'
    }

    RecommendationService.recommended_poms(offender, poms)
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

  def suitability_detail
    @override[:suitability_detail] if @override.present?
  end
end
