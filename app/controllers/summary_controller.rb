# frozen_string_literal: true

class SummaryController < PrisonsApplicationController
  before_action :ensure_admin_user

  breadcrumb 'See allocations',
             -> { prison_summary_allocated_path(active_prison_id) },
             only: [:index, :allocated]
  breadcrumb 'Make allocations',
             -> { prison_summary_unallocated_path(active_prison_id) }, only: [:unallocated]
  breadcrumb 'Update information',
             -> { prison_summary_pending_path(active_prison_id) }, only: [:pending]

  def index
    redirect_to prison_summary_allocated_path(active_prison_id)
  end

  class SummaryPresenter
    attr_reader :unallocated_total, :allocated_total, :pending_total

    def initialize(summary)
      @unallocated_total = summary.unallocated.count
      @allocated_total = summary.allocated.count
      @pending_total = summary.pending.count
    end
  end

  def allocated
    summary = create_summary(:allocated)
    items = offenders(:allocated, summary.allocated)

    @offenders = Kaminari.paginate_array(items).page(page)
    @summary = SummaryPresenter.new summary
  end

  def unallocated
    summary = create_summary(:unallocated)
    items = offenders(:unallocated, summary.unallocated)

    @offenders = Kaminari.paginate_array(items).page(page)
    @summary = SummaryPresenter.new summary
  end

  def pending
    summary = create_summary(:pending)
    items = offenders(:pending, summary.pending)

    @offenders = Kaminari.paginate_array(items).page(page)
    @summary = SummaryPresenter.new summary
  end

private

  def offenders(summary_type, offenders)
    params = sort_params(summary_type)
    offenders.sort params[0], params[1]

    overrides_hash = Responsibility.where(nomis_offender_id: offenders.items.map(&:offender_no)).
      map { |r| [r.nomis_offender_id, r] }.to_h
    offenders.items.map { |o| OffenderPresenter.new(o, overrides_hash[o.offender_no]) }
  end

  def create_summary(summary_type)
    SummaryService.summary(
      summary_type, @prison
    )
  end

  def page
    params.fetch('page', 1).to_i
  end

  def sort_params(summary_type)
    if params['sort'].blank?
      return [:sentence_start_date, :asc] unless summary_type == :allocated

      return [nil, nil]
    end

    parts = params['sort'].split.map { |s| s.downcase.to_sym }
    return [parts[0], :asc] if parts.count == 1

    parts
  end
end
