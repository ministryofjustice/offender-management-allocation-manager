# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_case_info, only: [:edit, :edit_prd, :show]
  before_action :set_prisoner_from_url, only: [:new, :edit, :edit_prd, :show]

  def new
    @case_info = CaseInformation.new(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def edit; end

  # Just edit the parole_review_date field
  def edit_prd; end

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

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      welsh_offender: case_information_params[:welsh_offender],
      case_allocation: case_information_params[:case_allocation],
      manual_entry: true
    )

    if @case_info.valid?
      redirect_to prison_summary_pending_path(active_prison)
    else
      @prisoner = prisoner(case_information_params[:nomis_offender_id])
      render :new
    end
  end

  def update
    @case_info = CaseInformation.find_by(
      nomis_offender_id: case_information_params[:nomis_offender_id]
    )
    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    # The only item that can be badly entered is parole_review_date
    if @case_info.update(case_information_params.merge(manual_entry: true))
      redirect_to new_prison_allocation_path(active_prison, @case_info.nomis_offender_id)
    else
      render 'edit_prd'
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

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation, :welsh_offender,
             :parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end
end
