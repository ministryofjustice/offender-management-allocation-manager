class SarOffenderDataService
  attr_reader :nomis_offender_id, :start_date, :end_date

  def initialize(nomis_offender_id, start_date = nil, end_date = nil)
    @nomis_offender_id = nomis_offender_id
    @start_date = start_date
    @end_date = end_date
  end

  def find
    offender = by_offender_id(Offender, :state).first
    return nil if offender.nil?

    offender_data
  end

private

  def offender_data
    {
      nomsNumber: nomis_offender_id,
      allocationHistory: allocation_with_history,
      auditEvents: by_offender_id(AuditEvent, :event),
      calculatedEarlyAllocationStatus: by_offender_id(CalculatedEarlyAllocationStatus, :state).first,
      calculatedHandoverDate: by_offender_id(CalculatedHandoverDate, :state).first,
      caseInformation: by_offender_id(CaseInformation, :state).first,
      earlyAllocations: by_offender_id(EarlyAllocation, :event),
      emailHistories: by_offender_id(EmailHistory, :event),
      handoverProgressChecklist: by_offender_id(HandoverProgressChecklist, :state).first,
      offenderEmailSent: by_offender_id(OffenderEmailSent, :event),
      responsibility: by_offender_id(Responsibility, :state).first,
      victimLiaisonOfficers: by_offender_id(VictimLiaisonOfficer, :state),
    }
  end

  def allocation_with_history
    allocation = AllocationHistory.find_by(nomis_offender_id:)
    return [] if allocation.nil?

    transform_data(by_date([allocation] + allocation.get_old_versions, :state))
  end

  def by_offender_id(klass, algorithm)
    collection = klass.where(nomis_offender_id:)
    transform_data(by_date(collection, algorithm))
  end

  # @param items [Array, ActiveRecord_Relation]
  def by_date(items, algorithm)
    return items.sort_by(&:created_at) if start_date.blank? || end_date.blank?

    start_time = start_date.to_time
    end_time = (end_date + 1.day).to_time

    last_before_range = if algorithm == :state
                          [items.select { |i| i.created_at < start_time }.max_by(&:created_at)]
                        else
                          []
                        end

    within_range = items.select { |i| i.created_at >= start_time && i.created_at <= end_time }.sort_by(&:created_at)

    (last_before_range + within_range).compact
  end

  def transform_data(collection)
    return [] if collection.empty?

    presenter = presenter_for(collection)

    collection.map do |item|
      presenter.new(item).as_json
    end
  end

  def presenter_for(collection)
    presenter_klass = "Sar::#{collection.first.class.name.demodulize}"
    Object.const_defined?(presenter_klass) ? presenter_klass.constantize : Sar::GenericPresenter
  end
end
