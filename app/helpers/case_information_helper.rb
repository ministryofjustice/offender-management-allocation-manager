module CaseInformationHelper
  def delius_error_display(error_type)
    return nil if error_type.blank?

    "case_information/errors/#{ERROR_PARTIALS[error_type]}"
  end

  def prisoner_crn_display(prisoner, delius_data)
    if delius_data.size > 1
      delius_data.map(&:crn).map { |c| h(c) }.join('<br/>').html_safe
    else
      prisoner.crn
    end
  end

private

  ERROR_PARTIALS = {
    DeliusImportError::DUPLICATE_NOMIS_ID => 'duplicate_nomis_id',
    DeliusImportError::INVALID_TIER => 'invalid_tier',
    DeliusImportError::INVALID_CASE_ALLOCATION => 'invalid_case_allocation',
    DeliusImportError::MISSING_DELIUS_RECORD => 'missing_delius_record',
    DeliusImportError::MISSING_LDU => 'missing_ldu',
    DeliusImportError::MISSING_TEAM => 'missing_team',
    DeliusImportError::MISMATCHED_DOB => 'mismatched_dob'
  }.freeze
end
