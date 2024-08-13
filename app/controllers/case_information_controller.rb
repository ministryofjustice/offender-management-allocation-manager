# frozen_string_literal: true

class CaseInformationController < PrisonsApplicationController
  before_action :set_prisoner_from_url, only: [:new, :edit, :edit_thd, :update_thd]
  before_action :set_case_info, only: [:edit]

  before_action :set_referrer
  before_action :store_referrer_in_session, only: [:edit_thd, :edit]

  def new
    offender = Offender.find_by(nomis_offender_id: nomis_offender_id_from_url)
    return redirect_to('/404') if offender.nil?

    @case_info = offender.build_case_information
  end

  def edit; end

  # Just edit the target_hearing_date field
  def edit_thd
    @parole_form = TargetHearingDateForm.new
  end

  def update_thd
    @parole_form = TargetHearingDateForm.new target_hearing_date_params
    if @parole_form.valid?
      ParoleRecord.find_or_initialize_by(nomis_offender_id: nomis_offender_id_from_url)
                  .update!(parole_review_date: @parole_form.target_hearing_date)
      redirect_to referrer
    else
      render 'edit_thd'
    end
  end

  def create
    prisoner = Offender.find_by! nomis_offender_id: case_information_params[:nomis_offender_id]
    @case_info = prisoner.build_case_information(
      nomis_offender_id: case_information_params[:nomis_offender_id],
      tier: case_information_params[:tier],
      enhanced_resourcing: case_information_params[:enhanced_resourcing],
      manual_entry: true
    )

    if @case_info.save
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
    @case_info = Offender.find_by!(nomis_offender_id: case_information_params[:nomis_offender_id]).case_information
    @prisoner = prisoner(case_information_params[:nomis_offender_id])
    # Nothing here can fail due to radio buttons being unselectable
    @case_info.update!(case_information_params.merge(manual_entry: true))
    redirect_to referrer
  end

private

  def set_prisoner_from_url
    @prisoner = prisoner(nomis_offender_id_from_url)
  end

  def set_case_info
    prisoner = Offender.find_by!(nomis_offender_id: nomis_offender_id_from_url)
    @case_info = prisoner.case_information || prisoner.build_case_information
  end

  def prisoner(nomis_id)
    @prisoner ||= OffenderService.get_offender(nomis_id)
  end

  def nomis_offender_id_from_url
    params.require(:prisoner_id)
  end

  def case_information_params
    params.require(:case_information)
      .permit(:nomis_offender_id, :tier, :enhanced_resourcing)
  end

  def target_hearing_date_params
    params.require(:target_hearing_date_form)
      .permit(:target_hearing_date)
  end
end
