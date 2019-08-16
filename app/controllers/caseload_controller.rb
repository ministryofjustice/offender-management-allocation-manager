# frozen_string_literal: true

class CaseloadController < PrisonsApplicationController
  before_action :ensure_pom

  breadcrumb -> { 'Your caseload' }, -> { prison_caseload_index_path(active_prison) }
  breadcrumb -> { 'New cases' },
             -> { new_prison_caseload_path(active_prison) }, only: [:new]

  PAGE_SIZE = 20

  def index
    allocations = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    )

    @new_cases_count = allocations.select(&:new_case?).count
    allocations = filter_allocations(allocations)
    @total_allocations = allocations.count
    allocations = sort_allocations(allocations)

    @allocations = allocations.select.with_index { |_item, index|
      index >= offset && index < offset + PAGE_SIZE
    }

    @page_meta = new_page_meta(@total_allocations, @allocations.count)
  end

  def new
    @new_cases = PrisonOffenderManagerService.get_allocated_offenders(
      @pom.staff_id, active_prison
    ).select(&:new_case?)
  end

private

  def sort_allocations(allocations)
    if params['sort'].present?
      sort_field, sort_direction = params['sort'].split.map(&:to_sym)
    else
      sort_field = :last_name
      sort_direction = :asc
    end

    # cope with nil values by sorting using to_s - only dates and strings in these fields
    allocations = allocations.sort_by { |sentence| sentence.public_send(sort_field).to_s }
    allocations.reverse! if sort_direction == :desc

    allocations
  end

  def filter_allocations(allocations)
    if params['q'].present?
      @q = params['q']
      query = @q.upcase
      allocations = allocations.select { |a|
        a.full_name.upcase.include?(query) || a.nomis_offender_id.include?(query)
      }
    end
    if params['role'].present?
      allocations = allocations.select { |a|
        a.responsibility == params['role']
      }
    end
    allocations
  end

  def ensure_pom
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user,
      active_prison
    )

    if @pom.blank?
      redirect_to '/'
    end
  end

  def new_page_meta(total, count_on_page)
    PageMeta.new.tap { |meta|
      meta.size = PAGE_SIZE
      meta.total_elements = total
      meta.total_pages = (total + PAGE_SIZE - 1) / PAGE_SIZE
      meta.number = page
      meta.items_on_page = count_on_page
    }
  end

  def offset
    (PAGE_SIZE * page) - PAGE_SIZE
  end

  def page
    params.fetch('page', 1).to_i
  end
end
