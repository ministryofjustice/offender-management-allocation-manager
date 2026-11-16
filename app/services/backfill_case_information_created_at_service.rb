# frozen_string_literal: true

class BackfillCaseInformationCreatedAtService
  CASE_INFORMATION_INTRODUCED_AT = Time.utc(2019, 2, 14).freeze
  TIMESTAMPS_CUTOFF_DATE = Time.utc(2019, 8, 13).freeze
  ALLOCATION_ESTIMATE_CUTOFF_DATE = Time.utc(2020, 1, 1).freeze
  FALLBACK_CREATED_AT = Time.utc(2019, 8, 12, 23, 59, 59, 999_999).freeze
  BATCH_SIZE = 200

  def initialize(dry_run:)
    @dry_run = dry_run
    @counts = {
      missing_created_at: 0,
      paper_trail_create: 0,
      paper_trail_snapshot: 0,
      paper_trail_allocation_date: 0,
      paper_trail_changes: 0,
      allocation_created_at: 0,
      allocation_date: 0,
      fallback_date: 0,
      no_allocation: 0,
      no_usable_date: 0,
      before_case_information_introduced: 0,
      after_case_updated_at: 0,
      estimated_after_timestamps_cutoff: 0,
    }
    if dry_run
      @counts[:estimated_by_year] = Hash.new(0)
      @counts[:fallback_allocation_by_year] = Hash.new(0)
    end
  end

  def call
    CaseInformation.where(created_at: nil).in_batches(of: BATCH_SIZE) do |batch|
      cases = batch.select(:id, :nomis_offender_id, :updated_at).to_a
      allocations = AllocationHistory.where(nomis_offender_id: cases.map(&:nomis_offender_id))
                                     .select(:id, :nomis_offender_id, :created_at, :primary_pom_allocated_at)
                                     .index_by(&:nomis_offender_id)
      candidates = allocation_candidates(allocations.values)
      cases.each do |case_information|
        process_case(case_information, allocations[case_information.nomis_offender_id], candidates)
      end
    end

    @counts
  end

private

  def allocation_candidates(allocations)
    candidates = Hash.new { |hash, key| hash[key] = [] }

    allocations.each do |allocation|
      candidates[allocation.id] << [allocation.created_at, :allocation_created_at]
      candidates[allocation.id] << [allocation.primary_pom_allocated_at, :allocation_date]
    end

    PaperTrail::Version.where(item_type: 'AllocationHistory', item_id: allocations.map(&:id))
                       .select(:id, :item_id, :event, :created_at, :object, :object_changes)
                       .find_each do |version|
      candidates[version.item_id] << [version.created_at, :paper_trail_create] if version.event == 'create'
      add_version_dates(candidates[version.item_id], version)
    end
    candidates
  end

  def add_version_dates(candidates, version)
    serializer = PaperTrail.serializer
    if version.object.present?
      snapshot = serializer.load(version.object)
      candidates << [timestamp(snapshot['created_at'], version), :paper_trail_snapshot]
      candidates << [timestamp(snapshot['primary_pom_allocated_at'], version), :paper_trail_allocation_date]
    end
    return if version.object_changes.blank?

    changes = serializer.load(version.object_changes)
    %w[created_at primary_pom_allocated_at].each do |attribute|
      Array(changes[attribute]).each do |value|
        candidates << [timestamp(value, version), :paper_trail_changes]
      end
    end
  end

  def timestamp(value, version)
    return if value.nil?

    result = AllocationHistory.type_for_attribute('created_at').cast(value)
    raise ArgumentError, "Invalid allocation timestamp in PaperTrail version #{version.id}: #{value.inspect}" if result.nil?

    result
  end

  def process_case(case_information, allocation, candidates)
    @counts[:missing_created_at] += 1
    unless allocation
      @counts[:no_allocation] += 1
      return
    end

    dates = candidates[allocation.id].select { |date, _source| date.present? }
    if dates.empty?
      @counts[:no_usable_date] += 1
      return
    end

    date, source = dates.min_by(&:first)
    if date < CASE_INFORMATION_INTRODUCED_AT
      @counts[:before_case_information_introduced] += 1
      return
    end

    if date >= ALLOCATION_ESTIMATE_CUTOFF_DATE
      allocation_year = date.utc.year
      date = FALLBACK_CREATED_AT
      source = :fallback_date
    end

    if date > case_information.updated_at
      @counts[:after_case_updated_at] += 1
      return
    end

    # update_all bypasses callbacks and does not touch updated_at.
    CaseInformation.where(id: case_information.id).update_all(created_at: date) unless @dry_run
    @counts[source] += 1
    @counts[:estimated_after_timestamps_cutoff] += 1 if date >= TIMESTAMPS_CUTOFF_DATE
    @counts[:estimated_by_year][date.utc.year] += 1 if @dry_run
    @counts[:fallback_allocation_by_year][allocation_year] += 1 if @dry_run && source == :fallback_date
  end
end
