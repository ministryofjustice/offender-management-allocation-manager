# frozen_string_literal: true

class FemalePrisonersController < PrisonersController
  include Sorting

  before_action :ensure_spo_user
  before_action :load_all_offenders

  def allocated
    all_offenders = @prison.offenders
    active_allocations_hash = AllocationService.active_allocations(all_offenders.map(&:offender_no), @prison.code)
    allocated_offenders = load_offenders :allocated

    offenders = allocated_offenders.map { |offender| OffenderWithAllocationPresenter.new(offender, active_allocations_hash.fetch(offender.offender_no)) }
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render 'summary/allocated'
  end

  def missing_information
    offenders = load_offenders :missing_information
    @offenders = Kaminari.paginate_array(offenders).page(page)
  end

  def unallocated
    offenders = load_offenders :unallocated
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render 'summary/unallocated'
  end

  def new_arrivals
    offenders = load_offenders :new_arrivals
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render 'summary/new_arrivals'
  end

private

  def load_all_offenders
    unallocated = []
    missing_info = []
    new_arrivals = []
    allocated = []

    all_offenders = @prison.offenders
    active_allocations_hash = AllocationService.active_allocations(all_offenders.map(&:offender_no), @prison.code)

    all_offenders.each do |offender|
      if active_allocations_hash.has_key?(offender.offender_no)
        allocated << offender
      elsif offender.has_case_information? && offender.complexity_level.present?
        unallocated << offender
      elsif offender.prison_arrival_date.to_date == Time.zone.today
        new_arrivals << offender
      else
        missing_info << offender
      end
    end

    @missing_info = missing_info
    @unallocated = unallocated
    @new_arrivals = new_arrivals
    @allocated = allocated
  end

  def load_offenders bucket_name
    bucket = {
      unallocated: @unallocated,
      missing_information: @missing_info,
      new_arrivals: @new_arrivals,
      allocated: @allocated
    }.fetch(bucket_name)

    sort_collection(bucket, default_sort: :last_name)
  end
end
