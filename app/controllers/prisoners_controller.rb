# frozen_string_literal: true

class PrisonersController < PrisonsApplicationController
  # This is needed so that the breadcrumb can work correctly
  before_action :load_offender, only: [:show]

  breadcrumb 'Your caseload',
             -> { prison_caseload_index_path(active_prison_id) }, only: [:show]
  breadcrumb -> { @offender.full_name },
             -> { '' }, only: [:show]

  def show
    @prisoner = OffenderPresenter.new(@offender,
                                      Responsibility.find_by(nomis_offender_id: id_for_show_action))
    @tasks = PomTasks.new.for_offender(@prisoner)
    @allocation = Allocation.find_by(nomis_offender_id: @prisoner.offender_no)

    @primary_pom_name = helpers.fetch_pom_name(@allocation.primary_pom_nomis_id).titleize if @allocation.present?

    if @allocation.present? && @allocation.secondary_pom_name.present?
      @secondary_pom_name = fetch_pom_name(@allocation.secondary_pom_nomis_id).titleize
    end

    @pom_responsibility = pom_responsibility
    @keyworker = Nomis::Keyworker::KeyworkerApi.get_keyworker(
      active_prison_id, @prisoner.offender_no
    )

    case_information = CaseInformation.includes(:early_allocations).find_by(nomis_offender_id: id_for_show_action)
    # Only show an early allocation if it was completed after sentence start
    if case_information.present? && case_information.latest_early_allocation.present? &&
      case_information.latest_early_allocation.updated_at > @offender.sentence_start_date
      @early_allocation = case_information.latest_early_allocation
    end
  end

  def image
    @prisoner = OffenderService.get_offender(params[:prisoner_id])
    image_data = Nomis::Elite2::OffenderApi.get_image(@prisoner.booking_id)

    response.headers['Expires'] = 6.months.from_now.httpdate
    send_data image_data, type: 'image/jpg', disposition: 'inline'
  end

private

  def pom_responsibility
    @pom_responsibility ||= overridden_responsibility || calculated_responsibility
  end

  def overridden_responsibility
    override = Responsibility.find_by(nomis_offender_id: @offender.offender_no)
    return nil if override.nil?

    if override.value == Responsibility::PRISON
      ResponsibilityService::RESPONSIBLE.to_s
    else
      ResponsibilityService::SUPPORTING.to_s
    end
  end

  def calculated_responsibility
    ResponsibilityService.calculate_pom_responsibility(
      @offender
    )
  end

  def id_for_show_action
    params[:id]
  end

  def load_offender
    @offender = OffenderService.get_offender(id_for_show_action)
  end
end
