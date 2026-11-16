# frozen_string_literal: true

class BackfillCaseInformationCreatedAtService
  CASE_INFORMATION_INTRODUCED_AT = Time.utc(2019, 2, 14).freeze
  TIMESTAMPS_CUTOFF_DATE = Time.utc(2019, 8, 13).freeze
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
      no_allocation: 0,
      no_usable_date: 0,
      before_case_information_introduced: 0,
      after_timestamps_introduced: 0,
      after_case_updated_at: 0,
      changed_concurrently: 0,
    }
    if dry_run
      @counts[:estimated_by_year] = Hash.new(0)
      @counts[:merge_cases] = []
    end
  end

  def call
    CaseInformation.where(created_at: nil).in_batches(of: BATCH_SIZE) do |batch|
      cases = batch.select(:id, :nomis_offender_id, :updated_at).to_a
      allocations = AllocationHistory.where(nomis_offender_id: cases.map(&:nomis_offender_id))
                                     .select(:id, :nomis_offender_id, :created_at, :primary_pom_allocated_at)
                                     .index_by(&:nomis_offender_id)
      candidates = allocation_candidates(allocations.values)
      merge_ids = merged_nomis_ids(cases) if @dry_run

      cases.each do |case_information|
        candidate = process_case(case_information, allocations[case_information.nomis_offender_id], candidates)
        next unless @dry_run && merge_ids.include?(case_information.nomis_offender_id)

        @counts[:merge_cases] << {
          case_information_id: case_information.id,
          estimated_created_at: candidate&.first,
          source: candidate&.last,
        }
      end
    end

    @counts
  end

private

  def merged_nomis_ids(cases)
    ids = cases.map(&:nomis_offender_id)
    NomisIdMerge.where(old_nomis_id: ids).or(NomisIdMerge.where(new_nomis_id: ids))
                .pluck(:old_nomis_id, :new_nomis_id).flatten.to_set
  end

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
    raise "Missing updated_at for CaseInformation #{case_information.id}" if case_information.updated_at.nil?

    unless allocation
      @counts[:no_allocation] += 1
      return
    end

    dates = candidates[allocation.id].select { |date, _source| date.present? }
    if dates.empty?
      @counts[:no_usable_date] += 1
      return
    end

    dates.select! { |date, _source| date >= CASE_INFORMATION_INTRODUCED_AT }
    if dates.empty?
      @counts[:before_case_information_introduced] += 1
      return
    end

    dates.select! { |date, _source| date < TIMESTAMPS_CUTOFF_DATE }
    if dates.empty?
      @counts[:after_timestamps_introduced] += 1
      return
    end

    candidate = dates.select { |date, _source| date <= case_information.updated_at }.min_by(&:first)
    unless candidate
      @counts[:after_case_updated_at] += 1
      return
    end

    date, source = candidate
    if @dry_run
      @counts[source] += 1
      @counts[:estimated_by_year][date.utc.year] += 1
      candidate
    # update_all bypasses callbacks and does not touch updated_at.
    elsif CaseInformation.where(id: case_information.id, nomis_offender_id: case_information.nomis_offender_id, created_at: nil)
                         .where('updated_at >= ?', date)
                         .update_all(created_at: date) == 1
      @counts[source] += 1
    else
      @counts[:changed_concurrently] += 1
    end
  end
end
