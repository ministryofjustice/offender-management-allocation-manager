module CaseInformationHelper
  def delius_error_display(error_type)
    ERROR_MESSAGES.fetch(error_type)
  end

  def delius_email_message(error_type)
    EMAIL_MESSAGES.fetch(error_type, 'No match could be made.')
  end

  def prisoner_crn_display(prisoner, delius_data)
    if delius_data.size > 1
      delius_data.map(&:crn).map { |c| h(c) }.join('<br/>').html_safe
    else
      prisoner.crn
    end
  end

private

  ERROR_MESSAGES = {
    DeliusImportError::DUPLICATE_NOMIS_ID =>
      'More than one nDelius record found with this prisoner number.
         You need to update nDelius so there is only one record before you can allocate.',
    DeliusImportError::INVALID_TIER =>
      'nDelius record with matching prisoner number but no tiering
         calculation found. You need to update nDelius with the tiering calculation
         before you can allocate.',
    DeliusImportError::INVALID_CASE_ALLOCATION =>
      'nDelius record with matching prisoner number but no service provider
         information found. You need to update nDelius with the service provider
         before you can allocate.',
    DeliusImportError::MISSING_DELIUS_RECORD =>
      'No nDelius record found with this prisoner number. This may be because
      the case information has not yet been updated. This prisoner needs to be
      matched with an nDelius record before you can allocate.',
    DeliusImportError::MISSING_LDU => 'nDelius record with matching prisoner number
       but no local divisional unit (LDU) information found. You need to update nDelius
       with the LDU before you can allocate.',
    DeliusImportError::MISSING_TEAM => 'nDelius record found with matching prisoner
       number but no community team information found. You need to update nDelius with the
       team information before you can allocate.',
    DeliusImportError::MISMATCHED_DOB => 'nDelius record found with matching prisoner
       number but a different date of birth. You need to check the data in nDelius and
       correct before you can allocate.'
  }.freeze

  EMAIL_MESSAGES = {
    DeliusImportError::DUPLICATE_NOMIS_ID =>
      'There’s more than one nDelius record with this NOMIS number.',
    DeliusImportError::INVALID_TIER =>
      'There’s no tier recorded in nDelius. You may need to contact the sentencing court.',
    DeliusImportError::INVALID_CASE_ALLOCATION =>
      'There’s no service provider in nDelius. You may need to contact the sentencing court.',
    DeliusImportError::MISMATCHED_DOB =>
      'There’s an nDelius record with this NOMIS number but a different date of birth.'
  }
end
