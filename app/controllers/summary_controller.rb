# frozen_string_literal: true

class SummaryController < PrisonsApplicationController
  before_action :ensure_spo_user

  def index
    redirect_to allocated_prison_prisoners_path(active_prison_id)
  end

  def allocated
    summary = create_summary(:allocated)
    set_data(summary)
  end

  def unallocated
    summary = create_summary(:unallocated)
    set_data(summary)
  end

  def missing_information
    summary = create_summary(:missing_information)
    set_data(summary)
  end

  def new_arrivals
    summary = create_summary(:new_arrivals)
    set_data(summary)
  end

private

  def set_data(summary)
    @allocated_count = summary.allocated_total
    @unallocated_count = summary.unallocated_total
    @missing_info_count = summary.pending_total
    @new_arrivals_count = summary.new_arrivals_total

    @offenders = Kaminari.paginate_array(summary.offenders.to_a).page(page)
  end

  def create_summary(summary_type)
    SummaryService.new(summary_type, @prison, params['sort'])
  end
end
