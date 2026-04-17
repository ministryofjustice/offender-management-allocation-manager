# frozen_string_literal: true

class FemaleMissingInfosController < PrisonsApplicationController
  before_action :ensure_womens_prison
  before_action :load_prisoner
  before_action :load_missing_info

  def new
    return redirect_to next_step_path if @prisoner.complexity_level.present?

    set_next_step_required
    render :complexity_level
  end

  def update
    @missing_info.assign_attributes(step_params)
    set_next_step_required

    if @missing_info.valid?
      HmppsApi::ComplexityApi.save(
        @missing_info.nomis_offender_id, level: @missing_info.complexity_level, username: current_user, reason: nil
      )

      if @next_step_required
        session[complexity_saved_session_key] = true
        redirect_to next_step_path
      else
        redirect_to prison_prisoner_review_case_details_path(prison_id: active_prison_id, prisoner_id: @missing_info.nomis_offender_id)
      end
    else
      render :complexity_level
    end
  end

private

  def has_case_information?
    !!CaseInformation.find_by(nomis_offender_id: @missing_info.nomis_offender_id)&.complete_for_allocation?
  end

  def next_step_path
    new_prison_prisoner_case_information_path(active_prison_id, @missing_info.nomis_offender_id, sort: params[:sort], page: params[:page])
  end

  def load_prisoner
    @prisoner = OffenderService.get_offender(prisoner_id)
    redirect_to('/404') if @prisoner.nil?
  end

  def load_missing_info
    @missing_info = ComplexityForm.new(
      nomis_offender_id: prisoner_id,
      complexity_level: @prisoner.complexity_level
    )
  end

  def prisoner_id
    params.require(:prisoner_id)
  end

  def step_params
    params.fetch(:complexity_form, {}).permit(:complexity_level)
  end

  def ensure_womens_prison
    redirect_to('/404') unless PrisonService.womens_prison?(active_prison_id)
  end

  def complexity_saved_session_key
    "female_missing_info_complexity_saved_#{prisoner_id}"
  end

  def set_next_step_required
    @next_step_required = !has_case_information?
  end
end
