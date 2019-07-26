# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  def new
    @case_info = CaseInformation.new(
      nomis_offender_id: nomis_offender_id_from_url
    )

    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  def edit
    @case_info = CaseInformation.find_by(
      nomis_offender_id: nomis_offender_id_from_url
    )

    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  # rubocop:disable Metrics/MethodLength
  def show
    @case_info = CaseInformation.find_by(
      nomis_offender_id: nomis_offender_id_from_url
    )

    @prisoner = prisoner(nomis_offender_id_from_url)
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
  # rubocop:enable Metrics/MethodLength

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      omicable: case_information_params[:omicable],
      case_allocation: case_information_params[:case_allocation]
    )

    return redirect_to prison_summary_pending_path(active_prison) if @case_info.valid?

    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    render :new
  end

  def update
    case_info = CaseInformation.find_by(
      nomis_offender_id: case_information_params[:nomis_offender_id]
    )
    case_info.tier = case_information_params[:tier]
    case_info.case_allocation = case_information_params[:case_allocation]
    case_info.omicable = case_information_params[:omicable]
    case_info.save

    redirect_to new_prison_allocation_path(active_prison, case_info.nomis_offender_id)
  end

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      omicable: case_information_params[:omicable],
      case_allocation: case_information_params[:case_allocation],
      manual_entry: true
    )

    return redirect_to prison_summary_pending_path(active_prison) if @case_info.valid?

    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    render :new
  end

  def update
    case_info = CaseInformation.find_by(
      nomis_offender_id: case_information_params[:nomis_offender_id]
    )
    case_info.tier = case_information_params[:tier]
    case_info.case_allocation = case_information_params[:case_allocation]
    case_info.omicable = case_information_params[:omicable]
    case_info.manual_entry = true
    case_info.save

    redirect_to new_prison_allocation_path(active_prison, case_info.nomis_offender_id)
  end

private

  def prisoner(nomis_id)
    @prisoner ||= OffenderService.get_offender(nomis_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def case_information_params
    params.require(:case_information).
      permit(:nomis_offender_id, :tier, :case_allocation, :omicable)
  end
end
