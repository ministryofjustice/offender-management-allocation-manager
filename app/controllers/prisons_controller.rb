# frozen_string_literal: true

class PrisonsController < PrisonsApplicationController
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
end
