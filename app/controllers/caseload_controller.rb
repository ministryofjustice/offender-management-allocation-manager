# frozen_string_literal: true

class CaseloadController < ApplicationController
  before_action :authenticate_user
  before_action :ensure_pom

  breadcrumb 'Your caseload', :caseload_index_path, only: [:new]
  breadcrumb -> { 'Your caseload' },
             -> { caseload_index_path }, only: [:index]
  breadcrumb -> { 'New cases' },
             -> { new_caseload_path }, only: [:new]

  PAGE_SIZE = 10

  def index
    return if pom.blank?

    @allocations = PrisonOffenderManagerService.get_allocated_offenders(
      pom.staff_id, active_caseload,
      offset: offset, limit: PAGE_SIZE
    )
    @new_cases_count = PrisonOffenderManagerService.get_new_cases_count(
      pom.staff_id, active_caseload
    )

    @page_meta = new_page_meta(total_allocations, @allocations.count)
  end

  def new
    if pom.present?
      @new_cases = PrisonOffenderManagerService.get_new_cases(
        pom.staff_id, active_caseload
      )
    end
  end

private

  def total_allocations
    @total_allocations ||= PrisonOffenderManagerService.get_allocations_for_primary_pom(
      pom.staff_id, active_caseload
    ).count
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

  def pom
    @pom ||= PrisonOffenderManagerService.
        get_signed_in_pom_details(current_user, active_caseload)
  end

  def page
    params.fetch('page', 1).to_i
  end
end
