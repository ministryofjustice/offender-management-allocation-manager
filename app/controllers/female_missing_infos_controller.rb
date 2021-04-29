# frozen_string_literal: true

class FemaleMissingInfosController < PrisonsApplicationController
  include Wicked::Wizard

  before_action :load_missing_info, except: :new

  # We have to ignore these 2 keys whilst loading attributes
  IGNORED_ERROR_KEYS = ['errors', 'validation_context'].freeze

  steps :complexity_level, :delius_information

  def new
    session[complexity_session_key] = ComplexityForm.new nomis_offender_id: params.fetch(:prisoner_id)
    session[case_info_session_key] = CaseInformation.new nomis_offender_id: params.fetch(:prisoner_id),
                                              manual_entry: true
    if HmppsApi::ComplexityApi.get_complexity(params.fetch(:prisoner_id))
      redirect_to wizard_path :delius_information
    else
      redirect_to wizard_path(steps.first)
    end
  end

  def show
    @secondary_button = (step == :delius_information) || (step == :complexity_level && has_case_information?)
    render_wizard
  end

  def update
    @missing_info.assign_attributes(step_params)
    save_session

    if @missing_info.valid?
      if step == :complexity_level
        HmppsApi::ComplexityApi.save @missing_info.nomis_offender_id, level: @missing_info.complexity_level, username: current_user, reason: nil
        if has_case_information?
          complete_journey
        else
          redirect_to next_wizard_path
        end
      else
        @missing_info.save!
        complete_journey
      end
    else
      render_wizard
    end
  end

private

  def has_case_information?
    CaseInformation.find_by nomis_offender_id: @missing_info.nomis_offender_id
  end

  def complete_journey
    session.delete case_info_session_key
    session.delete complexity_session_key
    if params.fetch(:commit) == 'Update'
      redirect_to missing_information_prison_prisoners_path(@prison.code)
    else
      redirect_to prison_prisoner_staff_index_path(active_prison_id,  @missing_info.nomis_offender_id)
    end
  end

  def save_session
    if step == :complexity_level
      session[complexity_session_key] = @missing_info
    else
      session[case_info_session_key] = @missing_info
    end
  end

  def load_missing_info
    @prisoner = OffenderService.get_offender params.fetch(:prisoner_id)

    @missing_info = if step == :complexity_level
                      ComplexityForm.new session[complexity_session_key].except(*IGNORED_ERROR_KEYS)
                    else
                      CaseInformation.new session[case_info_session_key].except(*IGNORED_ERROR_KEYS)
                    end
  end

  def step_params
    if step == :complexity_level
      params.fetch(:complexity_form, {}).permit(:complexity_level)
    else
      params.fetch(:case_information, {}).permit(:case_allocation, :probation_service, :tier)
    end
  end

  def complexity_session_key
    'complexity_' + params.fetch(:prisoner_id)
  end

  def case_info_session_key
    'case_info_' + params.fetch(:prisoner_id)
  end
end
