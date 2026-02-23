# frozen_string_literal: true

class CoworkingController < PrisonsApplicationController
  include OffenderHelper

  def new
    @prisoner = offender(nomis_offender_id_from_url)
    current_pom_id = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id_from_url).primary_pom_nomis_id
    poms = @prison.get_list_of_poms
    @current_pom = poms.detect { |pom| pom.staff_id == current_pom_id }

    @active_poms, @unavailable_poms = poms.reject { |p| p.staff_id == current_pom_id }.partition do |pom|
      %w[active unavailable].include? pom.status
    end

    @prison_poms = @active_poms.select(&:prison_officer?)
    @probation_poms = @active_poms.select(&:probation_officer?)
  end

  def confirm
    @prisoner = offender(nomis_offender_id_from_url)
    @primary_pom = @prison.get_single_pom(primary_pom_id_from_url)
    @secondary_pom = @prison.get_single_pom(secondary_pom_id_from_url)
    @latest_allocation_details = session[:latest_allocation_details] = format_allocation(
      offender: @prisoner, pom: @primary_pom, view_context: view_context, co_working_pom: @secondary_pom)
  end

  def create
    AllocationService.allocate_secondary(
      nomis_offender_id: allocation_params[:nomis_offender_id],
      secondary_pom_nomis_id: allocation_params[:nomis_staff_id],
      created_by_username: current_user,
      message: allocation_params[:message]
    )

    session[:latest_allocation_details][:additional_notes] = allocation_params[:message]
    redirect_to allocated_prison_prisoners_path(active_prison_id)
  end

  def confirm_removal
    @allocation = AllocationHistory.find_by!(
      nomis_offender_id: coworking_nomis_offender_id_from_url
    )
    @prisoner = offender(@allocation.nomis_offender_id)

    if @allocation.primary_pom_nomis_id
      @primary_pom = @prison.get_single_pom(@allocation.primary_pom_nomis_id)
    end
  end

  def destroy
    @allocation = AllocationHistory.find_by!(
      nomis_offender_id: nomis_offender_id_from_url
    )

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

  def primary_pom_id_from_url
    params.require(:primary_pom_id)
  end
end
