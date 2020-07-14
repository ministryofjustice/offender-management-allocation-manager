# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_case_info, only: [:edit, :show]
  before_action :set_prisoner_from_url, only: [:new, :edit, :edit_prd, :update_prd, :show]

  def new
    @last_location = LastLocationForm.new(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def create
    if params[:stage] == 'last_location'
      @last_location = LastLocationForm.new(last_location_params)
      @case_info = CaseInformation.new(
        nomis_offender_id: @last_location.nomis_offender_id,
        probation_service: @last_location.probation_service,
        manual_entry: true
      )
      if @last_location.valid?
        unless @case_info.valid?
          @prisoner = prisoner(@last_location.nomis_offender_id)
          render :missing_info
        end
      else
        display_address_page
      end
    else
      @last_location = Struct.new(:valid?).new(true)
      @case_info = CaseInformation.new(case_information_params.merge(manual_entry: true))
      unless @case_info.valid?
        handle_stage2_rendering
      end
    end
    if @last_location.valid? && @case_info.valid?
      @case_info.save!
      send_email
      redirect_to prison_summary_pending_path(active_prison_id, sort: params[:sort], page: params[:page])
    end
  end

  def edit
    @edit_case_info = EditCaseInformation.from_case_info(@case_info)

    @team_name = @case_info.team&.name
  end

  def update
    @case_info = CaseInformation.find_by!(nomis_offender_id: nomis_offender_id_from_url)
    @prisoner = prisoner(nomis_offender_id_from_url)
    @edit_case_info = EditCaseInformation.new edit_case_information_params

    if @edit_case_info.valid?
      @case_info.update!(probation_service: @edit_case_info.probation_service,
                      tier: @edit_case_info.tier,
                      case_allocation: @edit_case_info.case_allocation,
                      team: @edit_case_info.team_id.blank? ? nil : Team.find(@edit_case_info.team_id),
                      manual_entry: true)
      # we only send email if the ldu is different from previous
      if CaseInformationService.ldu_changed?(@case_info.saved_change_to_team_id)
        send_email
      end
      redirect_to new_prison_allocation_path(active_prison_id, @case_info.nomis_offender_id)
    else
      render :edit
    end
  end

  # Just edit the parole_review_date field
  def edit_prd
    @case_info = ParoleReviewDateForm.new nomis_offender_id: nomis_offender_id_from_url
  end

  def update_prd
    @case_info = ParoleReviewDateForm.new nomis_offender_id: nomis_offender_id_from_url
    if @case_info.update(parole_review_date_params)
      redirect_to new_prison_allocation_path(active_prison_id, @case_info.nomis_offender_id)
    else
      render 'edit_prd'
    end
  end

  def show
    @delius_data = DeliusData.where(noms_no: nomis_offender_id_from_url)

    @delius_errors = if @delius_data.empty?
                       [DeliusImportError.new(
                         nomis_offender_id: nomis_offender_id_from_url,
                         error_type: DeliusImportError::MISSING_DELIUS_RECORD
                       )]
                     else
                       DeliusImportError.where(
                         nomis_offender_id: nomis_offender_id_from_url
                       )
                     end
    last_delius = DeliusData.order(:updated_at).last
    @next_update_date = if last_delius.present?
                          last_delius.updated_at + 1.day
                        else
                          Date.tomorrow
                        end
  end

private

  def set_prisoner_from_url
    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  def set_case_info
    @case_info = CaseInformation.find_by(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def prisoner(nomis_id)
    @prisoner ||= OffenderService.get_offender(nomis_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def display_address_page
    @prisoner = prisoner(@last_location.nomis_offender_id)
    render :new
  end

  def handle_stage2_rendering
    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    render :missing_info
  end

  def send_email
    return unless @case_info.probation_service == 'England' || @case_info.probation_service == 'Wales'

    prepare_email
  end

  def prepare_email
    spo = Nomis::Elite2::UserApi.user_details(current_user).email_address.try(:first)
    ldu = @case_info.team.try(:local_divisional_unit)
    emails = [ldu.try(:email_address), spo]
    delius_error = DeliusImportError.where(nomis_offender_id: @case_info.nomis_offender_id).first
    message = helpers.delius_email_message(delius_error&.error_type)
    notice_to_spo = helpers.spo_message(ldu)

    emails.reject(&:blank?).each do |email_address|
      notice_info = send_notice(email_address, spo, notice_to_spo)
      CaseAllocationEmailJob.perform_later(email: email_address,
                                           ldu: ldu,
                                           nomis_offender_id: @case_info.nomis_offender_id,
                                           message: message,
                                           notice: notice_info)
    end

    prisoner = prisoner(@case_info.nomis_offender_id)
    flash[:notice] = helpers.flash_notice_text(error_type: delius_error&.error_type, prisoner: prisoner,
                                               email_count: emails.compact.count)
    flash[:alert] = helpers.flash_alert_text(spo: spo, ldu: ldu, team_name: @case_info.team.name)
  end

  def send_notice(email, spo_email, notice)
    email == spo_email ? notice : ''
  end

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation,
             :parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy,
             :probation_service, :team_id)
  end

  def edit_case_information_params
    params.require(:edit_case_information).
      permit(:tier, :case_allocation, :team_id,
             :last_known_location,
             :last_known_address)
  end

  def last_location_params
    params.require(:last_location_form).
      permit(:nomis_offender_id,
             :last_known_address, :last_known_location)
  end

  def parole_review_date_params
    params.require(:parole_review_date_form).
      permit(:parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end
end
