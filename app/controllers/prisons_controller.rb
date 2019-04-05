# frozen_string_literal: true

class PrisonsController < ApplicationController
  before_action :authenticate_user

  def index
    @next = referer
  end

  def set_active
    redirect_path = next_page if redirect?
    redirect_path = root_path unless caseloads.include?(code)

    update_active_caseload(code)

    redirect_to redirect_path || root_path
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
