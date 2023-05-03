class Api::HandoversApiController < Api::ApiController
  respond_to :json

  def show
    @handover = Api::Handover[nomis_offender_id]
    if @handover
      render json: @handover.as_json
    else
      render_404
    end
  end

private

  def nomis_offender_id
    params.require(:id)
  end
end
