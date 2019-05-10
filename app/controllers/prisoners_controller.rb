# frozen_string_literal: true

class PrisonersController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'Your caseload', :caseload_index, only: [:show]
  breadcrumb -> { offender.full_name },
             -> { '' }, only: [:show]


  def show
    @prisoner = offender
  end

  def image
    image_data = Nomis::Custody::ImageApi.image_data(id)

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
