# frozen_string_literal: true

class OnboardingController < PrisonsApplicationController
  before_action :ensure_spo_user

  # track answers across steps
  before_action :setup_form, only: [:search, :position, :working_pattern, :check_answers]

  before_action :set_staff_id_being_onboarded, except: [:search, :error]
  before_action :set_pom_details, only: [:position, :working_pattern, :check_answers]

  rescue_from StandardError do |e|
    Rails.logger.error(e)
    Sentry.capture_exception(e)
    render :error
  end

  def search
    @total_results = 0

    if request.post?
      @onboarding_form.assign_attributes(
        pom_onboarding_form_params.permit(:search_query).merge(
          # reset other steps after a new search
          position: nil, schedule_type: nil, working_pattern: nil
        )
      )

      if @onboarding_form.valid?(:search)
        save_to_session(@onboarding_form)

        @results, @total_results = NomisUserRolesService.search_staff(
          @prison, @onboarding_form.search_query
        )
      end
    else
      @onboarding_form.search_query = nil
    end
  end

  def position
    if request.post?
      @onboarding_form.assign_attributes(
        pom_onboarding_form_params.permit(:position)
      )

      if @onboarding_form.valid?(:position)
        save_to_session(@onboarding_form)
        redirect_to next_step_or_cya(working_pattern_prison_onboarding_path)
      end
    end
  end

  def working_pattern
    if request.post?
      @onboarding_form.assign_attributes(
        pom_onboarding_form_params.permit(:schedule_type, :working_pattern)
      )

      if @onboarding_form.valid?(:working_pattern)
        save_to_session(@onboarding_form)
        redirect_to check_answers_prison_onboarding_path
      end
    end
  end

  def check_answers
    if request.post?
      NomisUserRolesService.add_pom(
        @prison, @staff_id,
        @onboarding_form.slice(:position, :schedule_type, :hours_per_week)
      )

      save_to_session(PomOnboardingForm.new) # reset session data

      redirect_to confirmation_prison_onboarding_path
    end
  end

  def confirmation
    @pom = @prison.get_single_pom(@staff_id)
  end

  def error; end

private

  def read_from_session
    session.fetch(:pom_onboarding, {})
  end

  def save_to_session(form)
    super(:pom_onboarding, form)
  end

  def setup_form
    @onboarding_form = PomOnboardingForm.new(read_from_session)
  end

  def set_staff_id_being_onboarded
    @staff_id = params[:staff_id].to_i
  end

  def set_pom_details
    @details = HmppsApi::NomisUserRolesApi.staff_details(@staff_id)
  end

  def next_step_or_cya(next_step)
    params[:from] == 'cya' ? check_answers_prison_onboarding_path : next_step
  end

  def pom_onboarding_form_params
    params.require(:pom_onboarding_form)
  end
end
