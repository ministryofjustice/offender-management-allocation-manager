# frozen_string_literal: true

class PrisonersController < PrisonsApplicationController
  # This is needed so that the breadcrumb can work correctly
  before_action :load_offender, only: [:show]

  breadcrumb 'Your caseload',
             -> { prison_caseload_index_path(active_prison) }, only: [:show]
  breadcrumb -> { @offender.full_name },
             -> { '' }, only: [:show]

  def show
    @prisoner = OffenderPresenter.new(@offender,
                                      Responsibility.find_by(nomis_offender_id: id_for_show_action))

    @tasks = PomTasks.new(active_prison).for_offender(@prisoner)

    @allocation = AllocationVersion.find_by(nomis_offender_id: @prisoner.offender_no)
    @pom_responsibility = ResponsibilityService.calculate_pom_responsibility(
      @offender
    )
    @keyworker = Nomis::Keyworker::KeyworkerApi.get_keyworker(
      active_prison, @prisoner.offender_no
    )
    @early_allocation = EarlyAllocation.find_by(nomis_offender_id: id_for_show_action)
  end

  def image
    @prisoner = OffenderService.get_offender(params[:prisoner_id])
    image_data = Nomis::Elite2::OffenderApi.get_image(@prisoner.booking_id)

    response.headers['Expires'] = 6.months.from_now.httpdate
    send_data image_data, type: 'image/jpg', disposition: 'inline'
  end

private

  def id_for_show_action
    params[:id]
  end

  def load_offender
    @offender = OffenderService.get_offender(id_for_show_action)
  end
end
