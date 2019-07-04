# frozen_string_literal: true

class PrisonsController < ApplicationController
  before_action :authenticate_user

  def index
    @next = referer
    @prisons = caseloads
  end

private

  def referer
    return nil if request.referer.blank?

    u = URI(request.referer)
    url = u.path
    url += "?#{u.query}" if u.query.present?
    @referer ||= url
  end

  def code
    params.require(:code)
  end

  def next_page
    params[:next]
  end

  def redirect?
    params[:next].present?
  end
end
