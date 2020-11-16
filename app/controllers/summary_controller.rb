# frozen_string_literal: true

class SummaryController < PrisonsApplicationController
  before_action :ensure_spo_user

  def index
    redirect_to prison_summary_allocated_path(active_prison_id)
  end

  def allocated
    @summary = create_summary(:allocated)

    @offenders = Kaminari.paginate_array(@summary.offenders.map { |o| OffenderPresenter.new(o) }).page(page)
  end

  def unallocated
    @summary = create_summary(:unallocated)
    @offenders = Kaminari.paginate_array(@summary.offenders.map { |o| OffenderPresenter.new(o) }).page(page)
  end

  def pending
    @summary = create_summary(:pending)
    @offenders = Kaminari.paginate_array(@summary.offenders.map { |o| OffenderPresenter.new(o) }).page(page)
  end

  def new_arrivals
    @summary = create_summary(:new_arrivals)
    @offenders = Kaminari.paginate_array(@summary.offenders.map { |o| OffenderPresenter.new(o) }).page(page)
  end

private

  def create_summary(summary_type)
    SummaryService.new(summary_type, @prison, params['sort'])
  end
end
