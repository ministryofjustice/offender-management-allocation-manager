module CaseInformationHelper
  def delius_error_display(error_type)
    ERROR_MESSAGES.fetch(error_type)
  end

  def delius_email_message(error_type)
    EMAIL_MESSAGES.fetch(error_type, 'No match could be made.')
  end

  # rubocop:disable Metrics/MethodLength
  def flash_notice_text(error_type:, prisoner:, email_count:)
    case error_type
    when DeliusImportError::DUPLICATE_NOMIS_ID
      msg = "There’s more than one nDelius record with this NOMIS number #{prisoner.offender_no} for "\
            "#{prisoner.full_name}. The community probation team need to update nDelius."
    when DeliusImportError::MISSING_DELIUS_RECORD
      msg = "There’s no nDelius match for #{prisoner.full_name}, NOMIS number #{prisoner.offender_no}. The community "\
            'probation team need to update nDelius.'
    when DeliusImportError::INVALID_TIER
      msg = "There’s no tier recorded in nDelius for #{prisoner.full_name}, NOMIS number #{prisoner.offender_no}. "\
            'The community probation team need to update nDelius.'
    when DeliusImportError::INVALID_CASE_ALLOCATION
      msg = "There’s no service provider in nDelius for #{prisoner.full_name}, NOMIS number #{prisoner.offender_no}. "\
            'The community probation team need to update nDelius.'
    when DeliusImportError::MISMATCHED_DOB
      msg = "There’s an nDelius record with NOMIS number #{prisoner.offender_no} - #{prisoner.full_name} but a "\
            'different date of birth. The community probation team need to update nDelius.'
    else
      msg = "#{prisoner.full_name}, NOMIS number #{prisoner.offender_no} must be linked to an nDelius record for "\
            'handover to the community. The community probation team need to update nDelius.'
    end

    email_count > 0 ? msg + ' Automatic email sent.' : msg
  end
  # rubocop:enable Metrics/MethodLength

  def flash_alert_text(spo:, ldu:, team_name:)
    msg = ''

    if ldu.nil?
      msg += "An email could not be sent to the LDU for #{team_name} because there is no LDU assigned to the team. "
    elsif ldu.email_address.nil?
      msg += "An email could not be sent to the community probation team - #{ldu.name} because there is no "\
      'email address saved. You need to find an alternative way to contact them. '
    end

    if spo.nil?
      msg += 'We could not send you an email because there is no valid email address saved to your account. '\
      'You need to contact the local system administrator in your prison to update your email address.'
    end

    msg
  end

  def prisoner_crn_display(prisoner, delius_data)
    if delius_data.size > 1
      delius_data.map(&:crn).map { |c| h(c) }.join('<br/>').html_safe
    else
      prisoner.crn
    end
  end

  def spo_message(ldu)
    if ldu.email_address.blank?
      "We were unable to send an email to #{ldu.name} as we do not have their email address. "\
      'You need to find another way to provide them with this information.'
    else
      'This is a copy of the email sent to the LDU for your records'
    end
  end

private

  ERROR_MESSAGES = {
    DeliusImportError::DUPLICATE_NOMIS_ID =>
      'More than one nDelius record found with this prisoner number. '\
      'You need to update nDelius so there is only one record before you can allocate.',
    DeliusImportError::INVALID_TIER =>
      'nDelius record with matching prisoner number but no tiering calculation found. '\
      'You need to update nDelius with the tiering calculation before you can allocate.',
    DeliusImportError::INVALID_CASE_ALLOCATION =>
      'nDelius record with matching prisoner number but no service provider information found. '\
      'You need to update nDelius with the service provider before you can allocate.',
    DeliusImportError::MISSING_DELIUS_RECORD =>
      'No nDelius record found with this prisoner number. This may be because the case information has not yet '\
      'been updated. This prisoner needs to be matched with an nDelius record before you can allocate.',
    DeliusImportError::MISSING_LDU =>
      'nDelius record with matching prisoner number but no local divisional unit (LDU) information found. '\
      'You need to update nDelius with the LDU before you can allocate.',
    DeliusImportError::MISSING_TEAM =>
      'nDelius record found with matching prisoner number but no community team information found. '\
      'You need to update nDelius with the team information before you can allocate.',
    DeliusImportError::MISMATCHED_DOB =>
      'nDelius record found with matching prisoner number but a different date of birth. '\
      'You need to check the data in nDelius and correct before you can allocate.'
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
  }.freeze
end
