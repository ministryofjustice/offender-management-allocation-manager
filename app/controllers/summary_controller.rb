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
  breadcrumb 'Newly arrived', -> { prison_summary_new_arrivals_path(active_prison_id) }, only: :new_arrivals

  def index
    redirect_to prison_summary_allocated_path(active_prison_id)
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

  def new_arrivals
    summary = create_summary(:new_arrivals)
    items = offenders(:new_arrivals, summary.new_arrivals)

    @offenders = Kaminari.paginate_array(items).page(page)
    @summary = SummaryPresenter.new summary
  end

private

  def offenders(summary_type, offenders)
    params = sort_params(summary_type)
    offenders.sort params[0], params[1]

    # TODO: bug fix is to bring this data into scope and attach it to the OffenderPresenter
    # overrides_hash = Responsibility.where(nomis_offender_id: offenders.items.map(&:offender_no)).
    #   map { |r| [r.nomis_offender_id, r] }.to_h
    offenders.items.map { |o| OffenderPresenter.new(o, nil) }
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
