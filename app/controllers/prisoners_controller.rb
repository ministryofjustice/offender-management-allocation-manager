# frozen_string_literal: true

class PrisonersController < PrisonsApplicationController
  breadcrumb 'Your caseload',
             -> { prison_caseload_index_path(active_prison) }, only: [:show]
  breadcrumb -> { offender.full_name },
             -> { '' }, only: [:show]

  def show
    @prisoner = offender
    @allocation = AllocationService.current_allocation_for(@prisoner.offender_no)
    @pom_responsibility = ResponsibilityService.calculate_pom_responsibility(
      offender
    )
    @keyworker = Nomis::Keyworker::KeyworkerApi.get_keyworker(
      active_prison, @prisoner.offender_no
    )
  end

  def image
    @prisoner = offender
    image_data = Nomis::Elite2::OffenderApi.get_image(@prisoner.latest_booking_id)

    response.headers['Expires'] = 6.months.from_now.httpdate
    send_data image_data, type: 'image/jpg', disposition: 'inline'
  end

private

  def id
    @id ||= params[:id]
  end

  def offender
    @offender ||= OffenderService.get_offender(id)
  end
end
