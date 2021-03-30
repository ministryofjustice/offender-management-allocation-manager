# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_case_info, only: [:edit, :show]
  before_action :set_prisoner_from_url, only: [:new, :edit, :edit_prd, :update_prd, :show]
  before_action :set_referrer
  before_action :store_referrer_in_session, only: [:edit_prd]

  def new
    @case_info = CaseInformation.new(
      nomis_offender_id: nomis_offender_id_from_url
    )
  end

  def edit; end

  # Just edit the parole_review_date field
  def edit_prd
    @case_info = ParoleReviewDateForm.new nomis_offender_id: nomis_offender_id_from_url
  end

  def update_prd
    @case_info = ParoleReviewDateForm.new nomis_offender_id: nomis_offender_id_from_url
    if @case_info.update(parole_review_date_params)
      redirect_to referrer
    else
      render 'edit_prd'
    end
  end

  def show
    @delius_errors = DeliusImportError.where(nomis_offender_id: nomis_offender_id_from_url)
  end

  def create
    @case_info = CaseInformation.create(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      probation_service: case_information_params[:probation_service],
      case_allocation: case_information_params[:case_allocation],
      manual_entry: true
    )

    if @case_info.valid?
      if params.fetch(:commit) == 'Save'
        redirect_to missing_information_prison_prisoners_path(active_prison_id,
                                                              sort: params[:sort],
                                                              page: params[:page]
                    )
      else
        redirect_to prison_prisoner_staff_index_path(active_prison_id,  @case_info.nomis_offender_id)
      end
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
    # Nothing here can fail due to radio buttons being unselectable
    @case_info.update!(case_information_params.merge(manual_entry: true))
    redirect_to prison_prisoner_staff_index_path(active_prison_id, @case_info.nomis_offender_id)
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
      permit(:nomis_offender_id, :tier, :case_allocation, :probation_service,
             :parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end

  def parole_review_date_params
    params.require(:parole_review_date_form).
      permit(:parole_review_date_dd, :parole_review_date_mm, :parole_review_date_yyyy)
  end
end
