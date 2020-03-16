# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_case_info, only: [:edit, :show]
  before_action :set_prisoner_from_url, only: [:new, :edit, :edit_prd, :update_prd, :show]

  def new
    @case_info = CaseInformation.new(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      case_allocation: case_information_params[:case_allocation],
      probation_service: case_information_params[:probation_service],
      last_known_location: case_information_params[:last_known_location],
      team_id: case_information_params[:team_id],
      manual_entry: true
    )

    if params[:stage] == 'last_location'
      handle_stage1
    elsif params[:stage] == 'missing_info'
      handle_stage2
    end

    if @case_info.valid?
      @case_info.save
      redirect_to prison_summary_pending_path(active_prison_id, sort: params[:sort], page: params[:page])
    end
  end

  def edit
    @case_info.last_known_location = if @case_info.probation_service == 'England'
                                       'No'
                                     else
                                       'Yes'
                                     end
  end

  def update
    @case_info = CaseInformation.find_by(nomis_offender_id: case_information_params[:nomis_offender_id])
    @prisoner = prisoner(case_information_params[:nomis_offender_id])

    if case_information_updated?
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

    if @delius_data.empty?
      @delius_errors = [DeliusImportError.new(
        nomis_offender_id: nomis_offender_id_from_url,
        error_type: DeliusImportError::MISSING_DELIUS_RECORD
      )]
    else
      @delius_errors = DeliusImportError.where(
        nomis_offender_id: nomis_offender_id_from_url
      )
    end
    last_delius = DeliusData.order(:updated_at).last
    if last_delius.present?
      @next_update_date = last_delius.updated_at + 1.day
    else
      @next_update_date = Date.tomorrow
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

  def stage1_errors
    if case_information_params[:last_known_location].nil?
      @case_info.errors.messages.reject! do |f, _m|
        f != :probation_service && f != :last_known_location
      end
      display_address_page
    elsif case_information_params[:last_known_location] == 'Yes' && case_information_params[:probation_service].nil?
      @case_info.errors.messages.select! do |f, _m|
        f == :probation_service
      end
      display_address_page
    end
  end

  def display_address_page
    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    render :new
  end

  def handle_stage1
    if @case_info.scottish_or_ni?
      @case_info.save_scottish_or_ni
    elsif @case_info.english_or_welsh?
      @prisoner = prisoner(case_information_params[:nomis_offender_id])
      @case_info.errors.clear
      render :missing_info
    else
      stage1_errors
    end
  end

  def handle_stage2
    @case_info.probation_service = 'England' if @case_info.english?

    unless @case_info.stage2_filled?
      @prisoner = prisoner(case_information_params[:nomis_offender_id])
      @case_info.errors.messages.reject! do |f, _m|
        [:welsh_offender, :probation_service].include?(f)
      end
      render :missing_info
    end
  end

  def case_information_updated?
    if ['Scotland', 'Northern Ireland'].include?(case_information_params[:probation_service]) &&
      case_information_params[:last_known_location] == 'Yes'
      @case_info.update(probation_service: case_information_params[:probation_service], tier: 'N/A',
                        case_allocation: 'N/A', team: nil, manual_entry: true)
    else
      @case_info.probation_service = if case_information_params[:last_known_location] == 'No'
                                       'England'
                                     else
                                       case_information_params[:probation_service]
                                     end
      @case_info.update(probation_service: @case_info.probation_service, tier: case_information_params[:tier],
                        case_allocation: case_information_params[:case_allocation],
                        team_id: case_information_params[:team_id], manual_entry: true)
    end
  end

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation,
             :parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy,
             :probation_service, :last_known_location, :team_id)
  end

  def parole_review_date_params
    params.require(:parole_review_date_form).
      permit(:parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end
end
