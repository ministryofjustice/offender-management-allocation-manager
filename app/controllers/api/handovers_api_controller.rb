class Api::HandoversApiController < Api::ApiController
  respond_to :json

  def show
    @handover = CalculatedHandoverDate.find_by(nomis_offender_id: params[:id])

    if @handover.present?
      render json: Api::Handover.new(@handover)
    else
      render_404
    end
  end
end
