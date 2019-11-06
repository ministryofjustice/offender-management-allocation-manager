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

  def allocated
    @summary = create_summary(:allocated)
  end

  def unallocated
    @summary = create_summary(:unallocated)
  end

  def pending
    @summary = create_summary(:pending)
  end

private

  def create_summary(summary_type)
    field, direction = sort_params(summary_type)

    params = SummaryService::SummaryParams.new(
      sort_field: field,
      sort_direction: direction
    )

    SummaryService.summary(
      summary_type, @prison, page, params
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
