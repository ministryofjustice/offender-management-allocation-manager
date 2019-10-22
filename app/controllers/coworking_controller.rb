# frozen_string_literal: true

class CoworkingController < PrisonsApplicationController
  def new
    @prisoner = offender(nomis_offender_id_from_url)
    @current_pom = AllocationService.current_pom_for(
      nomis_offender_id_from_url,
      active_prison_id
    )

    # get_pom and get_poms return different data - so have to compare theit staff_ids.
    poms = PrisonOffenderManagerService.get_poms(active_prison_id).reject { |pom|
      pom.staff_id == @current_pom.staff_id
    }

    @active_poms, @unavailable_poms = poms.partition { |pom|
      %w[active unavailable].include? pom.status
    }

    @prison_poms = @active_poms.select{ |pom| pom.position.include?('PRO') }
    @probation_poms = @active_poms.select{ |pom| pom.position.include?('PO') }
  end

  def confirm
    @prisoner = offender(nomis_offender_id_from_url)
    @primary_pom = PrisonOffenderManagerService.get_pom(
      active_prison_id, primary_pom_id_from_url
    )
    @secondary_pom = PrisonOffenderManagerService.get_pom(
      active_prison_id, secondary_pom_id_from_url
    )
  end

  def create
    offender = offender(allocation_params[:nomis_offender_id])
    pom = PrisonOffenderManagerService.get_pom(
      active_prison_id,
      allocation_params[:nomis_staff_id]
    )

    AllocationService.allocate_secondary(
      nomis_offender_id: allocation_params[:nomis_offender_id],
      secondary_pom_nomis_id: allocation_params[:nomis_staff_id],
      created_by_username: current_user,
      message: allocation_params[:message]
    )
    redirect_to prison_summary_unallocated_path(active_prison_id),
                notice: "#{offender.full_name_ordered} has been allocated to #{pom.full_name_ordered} (#{pom.grade})"
  end

  def confirm_removal
    @prisoner = offender(coworking_nomis_offender_id_from_url)

    @responsibility_type = ResponsibilityService.calculate_pom_responsibility(@prisoner)

    @allocation = AllocationVersion.find_by!(
      nomis_offender_id: coworking_nomis_offender_id_from_url
    )
    @primary_pom = PrisonOffenderManagerService.get_pom(
      active_prison_id, @allocation.primary_pom_nomis_id
    )
  end

  def destroy
    @allocation = AllocationVersion.find_by!(
      nomis_offender_id: nomis_offender_id_from_url
    )

    secondary_pom_name = @allocation.secondary_pom_name

    @allocation.update!(
      secondary_pom_name: nil,
      secondary_pom_nomis_id: nil,
      event: AllocationVersion::DEALLOCATE_SECONDARY_POM,
      event_trigger: AllocationVersion::USER
    )

    EmailService.instance(allocation: @allocation,
                          message: '',
                          pom_nomis_id: @allocation.primary_pom_nomis_id
    ).send_cowork_deallocation_email(secondary_pom_name)

    redirect_to prison_allocation_path(active_prison_id, nomis_offender_id_from_url)
  end

private

  def allocation_params
    params.require(:coworking_allocations).
      permit(:message, :nomis_offender_id, :nomis_staff_id)
  end

  def offender(nomis_offender_id)
    OffenderService.get_offender(nomis_offender_id)
  end

  def coworking_nomis_offender_id_from_url
    params.require(:coworking_nomis_offender_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def secondary_pom_id_from_url
    params.require(:secondary_pom_id)
  end

  def primary_pom_id_from_url
    params.require(:primary_pom_id)
  end
end
