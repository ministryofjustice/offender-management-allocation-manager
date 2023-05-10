# frozen_string_literal: true

class Api::OffendersController < Api::ApiController
  respond_to :json

  def show
    @offender = OffenderService.get_offender(offender_number)
    if @offender.nil?
      render_404('Not found')
    else
      render json: offender_as_json(@offender)
    end
  end

private

  def offender_number
    params.require(:nomis_offender_id)
  end

  def offender_as_json(offender)
    {
      'offender_no' => offender.offender_no,
      'nomsNumber' => offender.offender_no,
      'early_allocation_eligibility_status' => offender.early_allocation?,
    }
  end
end
