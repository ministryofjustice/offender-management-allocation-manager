class FemalePrisonersController < PrisonsApplicationController
  include Sorting

  before_action :ensure_spo_user

  def allocated
    all_offenders = @prison.offenders
    active_allocations_hash = AllocationService.active_allocations(all_offenders.map(&:offender_no), @prison.code)
    allocated_offenders = load_offenders :allocated, all_offenders, active_allocations_hash

    offenders = allocated_offenders.map { |offender| OffenderWithPomName.new(offender, active_allocations_hash.fetch(offender.offender_no)) }
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render 'summary/allocated'
  end

  def missing_information
    all_offenders = @prison.offenders
    active_allocations_hash = AllocationService.active_allocations(all_offenders.map(&:offender_no), @prison.code)
    offenders = load_offenders :missing_information, all_offenders, active_allocations_hash
    @offenders = Kaminari.paginate_array(offenders).page(page)
  end

  def unallocated
    all_offenders = @prison.offenders
    active_allocations_hash = AllocationService.active_allocations(all_offenders.map(&:offender_no), @prison.code)
    offenders = load_offenders :unallocated, all_offenders, active_allocations_hash
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render 'summary/unallocated'
  end

  def new_arrivals
    all_offenders = @prison.offenders
    active_allocations_hash = AllocationService.active_allocations(all_offenders.map(&:offender_no), @prison.code)
    offenders = load_offenders :new_arrivals, all_offenders, active_allocations_hash
    @offenders = Kaminari.paginate_array(offenders).page(page)
    render 'summary/new_arrivals'
  end

private

  def load_offenders bucket_name, all_offenders, active_allocations_hash
    unallocated = []
    missing_info = []
    new_arrivals = []
    allocated = []

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

    @missing_info_count = missing_info.size
    @unallocated_count = unallocated.size
    @new_arrivals_count = new_arrivals.size
    @allocated_count = allocated.size

    bucket = {
      unallocated: unallocated,
      missing_information: missing_info,
      new_arrivals: new_arrivals,
      allocated: allocated
    }.fetch(bucket_name)

    sort_collection(bucket, default_sort: :last_name)
  end

  def page
    params.fetch('page', 1).to_i
  end
end
