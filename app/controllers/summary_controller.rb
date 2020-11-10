# frozen_string_literal: true

class SummaryController < PrisonsApplicationController
  before_action :ensure_spo_user

  breadcrumb 'See allocations',
             -> { prison_summary_allocated_path(active_prison_id) },
             only: [:index, :allocated]
  breadcrumb 'Make allocations',
             -> { prison_summary_unallocated_path(active_prison_id) }, only: [:unallocated]
  breadcrumb 'Update information',
             -> { prison_summary_pending_path(active_prison_id) }, only: [:pending]
  breadcrumb 'Newly arrived', -> { prison_summary_new_arrivals_path(active_prison_id) }, only: :new_arrivals

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
