class SarOffenderDataServiceV1
  attr_reader :nomis_offender_id, :start_date, :end_date

  def initialize(nomis_offender_id, start_date = nil, end_date = nil)
    @nomis_offender_id = nomis_offender_id
    @start_date = start_date
    @end_date = end_date
  end

  def find
    return nil unless Offender.exists?(nomis_offender_id:)

    offender_data
  end

private

  def offender_data
    {
      nomsNumber: nomis_offender_id,
      allocationHistory: allocation_with_history,
      calculatedHandoverDate: by_offender_id(CalculatedHandoverDate, :state).first,
      caseInformation: by_offender_id(CaseInformation, :state).first,
      earlyAllocations: by_offender_id(EarlyAllocation, :event),
      handoverProgressChecklist: by_offender_id(HandoverProgressChecklist, :state).first,
      responsibility: by_offender_id(Responsibility, :state).first,
    }
  end

  def allocation_with_history
    allocation = AllocationHistory.find_by(nomis_offender_id:)
    return [] if allocation.nil?

    # Each reified allocation state takes effect at its `updated_at` timestamp
    transform_data(
      by_date([allocation] + allocation.get_old_versions, :state, timestamp_attribute: :updated_at)
        .sort_by(&:updated_at)
        .reverse
    )
  end

  def by_offender_id(klass, algorithm)
    collection = klass.where(nomis_offender_id:)
    dated_collection = by_date(collection, algorithm)
    dated_collection = dated_collection.sort_by(&:created_at).reverse if algorithm == :event

    transform_data(dated_collection)
  end

  # @param items [Array, ActiveRecord_Relation]
  def by_date(items, algorithm, timestamp_attribute: :created_at)
    return items.sort_by(&:created_at) unless start_date || end_date

    start_time = start_date&.in_time_zone
    end_time = (end_date + 1.day).in_time_zone if end_date

    last_before_range = if algorithm == :state && start_time
                          [items.select {
                            timestamp = it.public_send(timestamp_attribute)
                            timestamp.present? && timestamp < start_time
                          }.max_by { it.public_send(timestamp_attribute) }]
                        else
                          []
                        end

    within_range = items.select {
      timestamp = it.public_send(timestamp_attribute)
      timestamp.present? && (!start_time || timestamp >= start_time) && (!end_time || timestamp < end_time)
    }.sort_by { it.public_send(timestamp_attribute) }

    (last_before_range + within_range).compact
  end

  def transform_data(collection)
    return [] if collection.empty?

    presenter = presenter_for(collection)

    collection.map { presenter.new(it).as_json }
  end

  def presenter_for(collection)
    presenter_klass = "Sar::#{collection.first.class.name.demodulize}"
    Object.const_defined?(presenter_klass) ? presenter_klass.constantize : Sar::GenericPresenter
  end
end
