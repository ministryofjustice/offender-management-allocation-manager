# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
class AllocationsController < PrisonsApplicationController
  delegate :update, to: :create

  breadcrumb 'Allocated', -> { prison_summary_allocated_path(active_prison) }, only: [:show]
  breadcrumb -> { offender(nomis_offender_id_from_url).full_name },
             -> { prison_allocation_path(active_prison, nomis_offender_id_from_url) }, only: [:show]

  def new
    @prisoner = offender(nomis_offender_id_from_url)
    @previously_allocated_pom_ids =
      AllocationService.previously_allocated_poms(nomis_offender_id_from_url)
    @recommended_poms, @not_recommended_poms =
      recommended_and_nonrecommended_poms_for(@prisoner)
    @unavailable_pom_count = unavailable_pom_count
  end

  def show
    @prisoner = offender(nomis_offender_id_from_url)
    primary_pom_nomis_id = AllocationVersion.find_by(nomis_offender_id: @prisoner.offender_no).primary_pom_nomis_id
    secondary_pom_nomis_id = AllocationVersion.find_by(nomis_offender_id: @prisoner.offender_no).secondary_pom_nomis_id
    @pom = PrisonOffenderManagerService.get_pom(active_prison, primary_pom_nomis_id)
    @coworker = PrisonOffenderManagerService.get_pom(active_prison, secondary_pom_nomis_id)
    @keyworker = Nomis::Keyworker::KeyworkerApi.get_keyworker(active_prison, @prisoner.offender_no)
    @allocation = AllocationVersion.find_by(nomis_offender_id: @prisoner.offender_no)
  end

  def edit
    allocation = AllocationService.current_allocation_for(nomis_offender_id_from_url)

    unless allocation.present? && allocation.active?
      redirect_to new_prison_allocation_path(active_prison, nomis_offender_id_from_url)
      return
    end

    @prisoner = offender(nomis_offender_id_from_url)
    @previously_allocated_pom_ids =
      AllocationService.previously_allocated_poms(nomis_offender_id_from_url)
    @recommended_poms, @not_recommended_poms =
      recommended_and_nonrecommended_poms_for(@prisoner)
    @unavailable_pom_count = unavailable_pom_count

    @current_pom = current_pom_for(nomis_offender_id_from_url)
  end

  def confirm
    @prisoner = offender(nomis_offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(
      active_prison,
      nomis_staff_id_from_url
    )
    @event = :allocate_primary_pom
    @event_trigger = :user
  end

  def confirm_reallocation
    @prisoner = offender(nomis_offender_id_from_url)
    @pom = PrisonOffenderManagerService.get_pom(
      active_prison,
      nomis_staff_id_from_url
    )
    @event = :reallocate_primary_pom
    @event_trigger = :user
  end

  # Note #update is delegated to #create
  def create
    offender = offender(allocation_params[:nomis_offender_id])
    @override = override
    allocation = allocation_attributes(offender)

    if AllocationService.create_or_update(allocation)
      flash[:notice] =
        "#{offender.full_name_ordered} has been allocated to #{pom.full_name_ordered} (#{pom.grade})"
    else
      flash[:alert] =
        "#{offender.full_name_ordered} has not been allocated  - please try again"
    end

    if allocation[:event] == 'allocate_primary_pom'
      redirect_to prison_summary_unallocated_path(active_prison, page: params[:page], sort: params[:sort])
    else
      redirect_to prison_summary_allocated_path(active_prison, page: params[:page], sort: params[:sort])
    end
  end

  def history
    @prisoner = offender(nomis_offender_id_from_url)
    @history = AllocationService.offender_allocation_history(nomis_offender_id_from_url)
    @pom_emails = AllocationService.allocation_history_pom_emails(@history)
  end

private

  def unavailable_pom_count
    @unavailable_pom_count ||= PrisonOffenderManagerService.unavailable_pom_count(
      active_prison
    )
  end

  def allocation_attributes(offender)
    {
      primary_pom_nomis_id: allocation_params[:nomis_staff_id].to_i,
      nomis_offender_id: allocation_params[:nomis_offender_id],
      event: allocation_params[:event],
      event_trigger: allocation_params[:event_trigger],
      created_by_username: current_user,
      nomis_booking_id: offender.latest_booking_id,
      allocated_at_tier: offender.tier,
      recommended_pom_type: recommended_pom_type(offender),
      prison: active_prison,
      override_reasons: override_reasons,
      suitability_detail: suitability_detail,
      override_detail: override_detail,
      message: allocation_params[:message]
    }
  end

  def offender(nomis_offender_id)
    OffenderPresenter.new(OffenderService.get_offender(nomis_offender_id),
                          Responsibility.find_by(nomis_offender_id: nomis_offender_id))
  end

  def pom
    @pom ||= PrisonOffenderManagerService.get_pom(
      active_prison,
      allocation_params[:nomis_staff_id]
    )
  end

  def override
    Override.where(
      nomis_offender_id: allocation_params[:nomis_offender_id]).
      where(nomis_staff_id: allocation_params[:nomis_staff_id]).last
  end

  def current_pom_for(nomis_offender_id)
    current_allocation = AllocationService.active_allocations(nomis_offender_id, active_prison)
    nomis_staff_id = current_allocation[nomis_offender_id]['primary_pom_nomis_id']

    PrisonOffenderManagerService.get_pom(active_prison, nomis_staff_id)
  end

  def recommended_pom_type(offender)
    rec_type = RecommendationService.recommended_pom_type(offender)
    rec_type == RecommendationService::PRISON_POM ? 'prison' : 'probation'
  end

  def recommended_and_nonrecommended_poms_for(offender)
    allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id_from_url)
    # don't allow primary to be the same as the co-working POM
    poms = PrisonOffenderManagerService.get_poms(active_prison).select { |pom|
      pom.status == 'active' && pom.staff_id != allocation.try(:secondary_pom_nomis_id)
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
    params.require(:allocations).permit(
      :nomis_staff_id,
      :nomis_offender_id,
      :message,
      :event,
      :event_trigger
    )
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
# rubocop:enable Metrics/LineLength
