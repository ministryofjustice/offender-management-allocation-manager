# frozen_string_literal: true

class HandoversController < PrisonsApplicationController
  before_action :ensure_spo_user

  def index
    @pending_handover_count = @current_user.pending_handover_offenders.count
    @summary = SummaryService.new(:handovers, @prison, params['sort'])
    @offenders = Kaminari.paginate_array(@summary.offenders.map { |o| OffenderPresenter.new(o) }).page(page)
  end
end
