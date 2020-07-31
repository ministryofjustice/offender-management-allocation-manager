# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_case_info, only: [:show]
  before_action :find_or_initialize_case_info, only: [:edit, :update]
  before_action :set_prisoner_from_url, only: [:edit, :update, :edit_prd, :update_prd, :show]

  def new
    # The edit journey automatically creates new records if they don't exist yet
    redirect_to edit_prison_case_information_path(@prison.code, nomis_offender_id_from_url)
  end

  def edit
    @probation_service_form = EditProbationServiceForm.new(
      nomis_offender_id: nomis_offender_id_from_url,
      probation_service: @case_info.probation_service
    )

    # Render page 1 of the edit form, where users will set the probation service
    render 'edit_probation_service'
  end

  def update
    case params[:form]
    when 'probation_service' # page 1 form was submitted
      update_probation_service
    when 'probation_data' # page 2 form was submitted
      update_probation_data
    else
      render body: 'Invalid form submission', status: :bad_request
    end
  end

  def update_probation_service
    @probation_service_form = EditProbationServiceForm.new(
      edit_probation_service_params
    )

    unless @probation_service_form.valid?
      # Show validation errors to user
      return render 'edit_probation_service'
    end

    @case_info.probation_service = @probation_service_form.probation_service

    if @case_info.requires_probation_data?
      # England/Wales
      # Render page 2 of the edit form to collect more info
      render 'edit_probation_data'
    else
      # Scotland/Northern Ireland
      # We don't need any more info - save and redirect
      save_case_info
    end
  end

  def update_probation_data
    data = edit_probation_data_params
    @case_info.assign_attributes(
      probation_service: data[:probation_service],
      tier: data[:tier],
      case_allocation: data[:case_allocation],
      team_id: data[:team_id],
    )

    if @case_info.valid?
      save_case_info
    else
      # Show validation errors to user
      render 'edit_probation_data'
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

  def find_or_initialize_case_info
    @case_info = CaseInformation.find_or_initialize_by(
      nomis_offender_id: nomis_offender_id_from_url
    )
    @case_info.manual_entry = true
  end

  def prisoner(nomis_id)
    @prisoner ||= OffenderService.get_offender(nomis_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def save_case_info
    new_record = @case_info.new_record?
    ldu_changed = @case_info.ldu_changed?

    @case_info.save!

    if @case_info.requires_probation_data? && ldu_changed
      send_email_to_ldu
    end

    if new_record
      redirect_to prison_summary_pending_path(active_prison_id, sort: params[:sort], page: params[:page])
    else
      redirect_to new_prison_allocation_path(active_prison_id, @case_info.nomis_offender_id)
    end
  end

  def send_email_to_ldu
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

  def edit_probation_service_params
    params.require(:edit_probation_service_form).
      permit(:nomis_offender_id, :last_known_address, :last_known_location)
  end

  def edit_probation_data_params
    params.require(:case_information).
      permit(:nomis_offender_id, :probation_service, :tier, :case_allocation, :team_id)
  end

  def parole_review_date_params
    params.require(:parole_review_date_form).
      permit(:parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end
end
