# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  before_action :ensure_spo_user

  def index
    @pending_handover_count = @current_user.allocations.count(&:approaching_handover?)
    @summary = SummaryService.new(:handovers, @prison, params['sort'])
    @offenders = Kaminari.paginate_array(@summary.offenders.to_a).page(page)
  end
end
