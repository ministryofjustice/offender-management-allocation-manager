# frozen_string_literal: true

class CoworkingController < PrisonsApplicationController
  def new
    @prisoner = offender(nomis_offender_id_from_url)
    current_pom_id = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id_from_url).primary_pom_nomis_id
    poms = @prison.get_list_of_poms
    @current_pom = poms.detect { |pom| pom.staff_id == current_pom_id }

    @active_poms, @unavailable_poms = poms.reject { |p| p.staff_id == current_pom_id }.partition { |pom|
      %w[active unavailable].include? pom.status
    }

    @prison_poms = @active_poms.select(&:prison_officer?)
    @probation_poms = @active_poms.select(&:probation_officer?)
    @case_info = Offender.includes(case_information: :early_allocations).find_by!(nomis_offender_id: nomis_offender_id_from_url).case_information
  end

  def confirm
    @prisoner = offender(nomis_offender_id_from_url)
    @primary_pom = @prison.get_single_pom(primary_pom_id_from_url)
    @secondary_pom = @prison.get_single_pom(secondary_pom_id_from_url)
  end

  def create
    offender = offender(allocation_params[:nomis_offender_id])
    pom = @prison.get_single_pom(allocation_params[:nomis_staff_id])

    AllocationService.allocate_secondary(
      nomis_offender_id: allocation_params[:nomis_offender_id],
      secondary_pom_nomis_id: allocation_params[:nomis_staff_id],
      created_by_username: current_user,
      message: allocation_params[:message]
    )
    redirect_to unallocated_prison_prisoners_path(active_prison_id),
                notice: "#{offender.full_name_ordered} has been allocated to #{view_context.full_name_ordered(pom)} (#{view_context.grade(pom)})"
  end

  def confirm_removal
    @prisoner = offender(coworking_nomis_offender_id_from_url)

    @allocation = AllocationHistory.find_by!(
      nomis_offender_id: coworking_nomis_offender_id_from_url
    )
    @primary_pom = @prison.get_single_pom(@allocation.primary_pom_nomis_id
    )
  end

  def destroy
    @allocation = AllocationHistory.find_by!(
      nomis_offender_id: nomis_offender_id_from_url
    )

    secondary_pom_name = @allocation.secondary_pom_name

    @allocation.update!(
      secondary_pom_name: nil,
      secondary_pom_nomis_id: nil,
      event: AllocationHistory::DEALLOCATE_SECONDARY_POM,
      event_trigger: AllocationHistory::USER
    )

    # stop double-bounces from sending invalid emails.
    if secondary_pom_name.present?
      EmailService.instance(allocation: @allocation,
                            message: '',
                            pom_nomis_id: @allocation.primary_pom_nomis_id
      ).send_cowork_deallocation_email(secondary_pom_name)
    end

    redirect_to prison_prisoner_allocation_path(active_prison_id, nomis_offender_id_from_url)
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
