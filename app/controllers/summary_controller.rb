class SummaryController < ApplicationController
  before_action :authenticate_user

  breadcrumb 'See allocations', :summary_allocated_path, only: [:index, :allocated]
  breadcrumb 'Make allocations', :summary_allocated_path, only: [:unallocated]
  breadcrumb 'Update information', :summary_allocated_path, only: [:pending]

  def index
    redirect_to summary_allocated_path
  end

  def allocated
    @summary = create_summary(:allocated)
    @page_meta = @summary.page_meta(page, :allocated)
  end

  def unallocated
    @summary = create_summary(:unallocated)
    @page_meta = @summary.page_meta(page, :unallocated)
  end

  def pending
    @summary = create_summary(:pending)
    @page_meta = @summary.page_meta(page, :pending)
  end

private

  def create_summary(summary_type)
    field, direction = sort_params(summary_type)

    params = SummaryService::SummaryParams.new(
      sort_field: field,
      sort_direction: direction,
      search: search_term
    )

    SummaryService.new.summary(
      summary_type, caseload, page, params
    )
  end

  def page
    params.fetch('page', 1).to_i
  end

  def search_term
    params['q']
  end

  def sort_params(summary_type)
    if params['sort'].blank?
      return [:sentence_date, :asc] unless summary_type == :allocated

      return [nil, nil]
    end

    parts = params['sort'].split.map { |s| s.downcase.to_sym }
    return [parts[0], :asc] if parts.count == 1

    parts
  end
end
