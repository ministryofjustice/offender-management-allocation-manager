class SarOffenderDataService
  def self.find(nomis_offender_id, _start_date = nil, _end_date = nil)
    offender = Offender.find_by(nomis_offender_id: nomis_offender_id)
    return nil if offender.nil?

    offender_data(nomis_offender_id)
  end

private

  def self.offender_data(offender_number)
    {
      nomsNumber: offender_number,
      allocationHistory: allocation_with_history(offender_number),
      auditEvents: jsonify_keys(AuditEvent.where(nomis_offender_id: offender_number)),
      calculatedEarlyAllocationStatus: jsonify_keys(CalculatedEarlyAllocationStatus.where(nomis_offender_id: offender_number)).first,
      calculatedHandoverDate: jsonify_keys(CalculatedHandoverDate.where(nomis_offender_id: offender_number)).first,
      caseInformation: jsonify_keys(CaseInformation.where(nomis_offender_id: offender_number)).first,
      earlyAllocations: jsonify_keys(EarlyAllocation.where(nomis_offender_id: offender_number)),
      emailHistories: jsonify_keys(EmailHistory.where(nomis_offender_id: offender_number)),
      handoverProgressChecklist: jsonify_keys(HandoverProgressChecklist.where(nomis_offender_id: offender_number)).first,
      offenderEmailSent: jsonify_keys(OffenderEmailSent.where(nomis_offender_id: offender_number)),
      paroleRecord: jsonify_keys(ParoleRecord.where(nomis_offender_id: offender_number)).first,
      responsibility: jsonify_keys(Responsibility.where(nomis_offender_id: offender_number)).first,
      victimLiaisonOfficers: jsonify_keys(VictimLiaisonOfficer.where(nomis_offender_id: offender_number)),
    }
  end

  def self.allocation_with_history(offender_number)
    allocation = AllocationHistory.find_by(nomis_offender_id: offender_number)
    return [] if allocation.nil?

    jsonify_keys([allocation] + allocation.get_old_versions)
  end

  def self.jsonify_keys(collection)
    return [] if collection.none?

    exclude_attributes = %w[id nomis_offender_id nomis_id]

    collection.map do |item|
      item.attributes
          .reject { |key, _val| exclude_attributes.include?(key) }
          .deep_transform_keys { |key| key.camelcase(:lower) }
    end
  end
end
