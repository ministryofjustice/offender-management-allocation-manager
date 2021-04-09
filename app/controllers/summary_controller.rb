# frozen_string_literal: true

class SummaryController < PrisonersController
  before_action :ensure_spo_user

  before_action :set_search_summary_data, only: :search

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

  def search
    super
  end

private

  def set_search_summary_data
    # pick an abrbitrary summary type
    # Populate fields required for search.html.erb
    set_buckets_from_summary create_summary(:new_arrivals)
  end

  def set_buckets_from_summary(summary)
    @allocated = summary.allocated
    @unallocated = summary.unallocated
    @missing_info = summary.pending
    @new_arrivals = summary.new_arrivals
  end

  def set_data(summary)
    set_buckets_from_summary summary

    @offenders = Kaminari.paginate_array(summary.offenders.to_a).page(page)
  end

  def create_summary(summary_type)
    SummaryService.new(summary_type, @prison, params['sort'])
  end
end
