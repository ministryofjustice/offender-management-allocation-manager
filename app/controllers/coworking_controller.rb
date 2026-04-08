# frozen_string_literal: true

class CoworkingController < PrisonsApplicationController
  def new
    clear_latest_allocation_details!

    @prisoner = offender(nomis_offender_id_from_url)
    current_pom_id = allocation_for!(nomis_offender_id_from_url).primary_pom_nomis_id
    poms = @prison.get_list_of_poms
    @current_pom = poms.detect { |pom| pom.staff_id == current_pom_id }

    @active_poms, @unavailable_poms = poms.reject { |p| p.staff_id == current_pom_id }.partition(&:active?)

    @prison_poms = @active_poms.select(&:prison_officer?)
    @probation_poms = @active_poms.select(&:probation_officer?)
  end

  def confirm
    clear_latest_allocation_details!

    @prisoner = offender(nomis_offender_id_from_url)
    @primary_pom = @prison.get_single_pom(allocation_for!(nomis_offender_id_from_url).primary_pom_nomis_id)
    @secondary_pom = @prison.get_single_pom(secondary_pom_id_from_url)
    @latest_allocation_details = build_latest_allocation_details(
      offender: @prisoner, pom: @primary_pom, co_working_pom: @secondary_pom
    )
  end

  def create
    nomis_offender_id = allocation_params[:nomis_offender_id]
    nomis_staff_id = allocation_params[:nomis_staff_id]
    additional_notes = allocation_params[:message]

    AllocationService.allocate_secondary(
      nomis_offender_id: nomis_offender_id,
      secondary_pom_nomis_id: nomis_staff_id,
      created_by_username: current_user,
      message: additional_notes
    )

    prisoner = offender(nomis_offender_id)
    allocation = allocation_for!(prisoner.offender_no)
    primary_pom = @prison.get_single_pom(allocation.primary_pom_nomis_id)
    secondary_pom = @prison.get_single_pom(nomis_staff_id)

    allocation_details = build_latest_allocation_details(
      offender: prisoner,
      pom: primary_pom,
      co_working_pom: secondary_pom
    )

    store_latest_allocation_details!(allocation_details, additional_notes:)

    redirect_to allocated_prison_prisoners_path(active_prison_id)
  end

  def confirm_removal
    @allocation = allocation_for!(coworking_nomis_offender_id_from_url)
    @prisoner = offender(@allocation.nomis_offender_id)

    if @allocation.primary_pom_nomis_id
      @primary_pom = @prison.get_single_pom(@allocation.primary_pom_nomis_id)
    end
  end

  def destroy
    @allocation = allocation_for!(nomis_offender_id_from_url)

    prisoner = offender(@allocation.nomis_offender_id)
    secondary_pom_name = @allocation.secondary_pom_name

    @allocation.deallocate_secondary_pom

    # stop double-bounces from sending invalid emails.
    if secondary_pom_name.present?
      if @allocation.active?
        EmailService.send_cowork_deallocation_email(
          allocation: @allocation,
          pom_nomis_id: @allocation.primary_pom_nomis_id,
          secondary_pom_name: secondary_pom_name
        )
      end

      notice = "#{secondary_pom_name} removed as co-working POM for #{prisoner.full_name_ordered}"
    else
      notice = nil
    end

    redirect_to helpers.prisoner_path_for_role(current_user_is_spo?, @prison, prisoner), notice:
  end

private

  def allocation_for!(nomis_offender_id)
    AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id)
  end

  def allocation_params
    params.require(:coworking_allocations)
      .permit(:message, :nomis_offender_id, :nomis_staff_id)
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
end
