# frozen_string_literal: true

module ApplicationHelper
  def format_date(date_obj, replacement: '')
    if date_obj
      date_obj.to_s(:rfc822)
    else
      replacement
    end
  end

  def format_date_long(date_obj)
    date_obj.strftime("#{date_obj.day.ordinalize} %B %Y") +
        ' (' + date_obj.strftime('%R') + ')'
  end

  def pom_level(level)
    {
      'PO' => 'Probation POM',
      'PRO' => 'Prison POM',
      'STAFF' => 'N/A'
    }.fetch(level)
  end

  def pom_level_long(level)
    {
      'PO' => 'Probation Officer POM',
      'PRO' => 'Prison Officer POM',
      'STAFF' => 'N/A'
    }.fetch(level)
  end

  def service_provider_label(provider)
    {
      'CRC' => t(:crc),
      'NPS' => t(:nps)
    }[provider]
  end

  def working_pattern_name(pattern)
    return 'Full time' if pattern.to_f == 1.0

    'Part time'
  end

  def sentence_type_label(offender)
    return 'Indeterminate' if offender.indeterminate_sentence?

    'Determinate'
  end

  def humanized_bool(bool_value)
    bool_value ? 'Yes' : 'No'
  end

  def auto_delius_import_enabled?(prison)
    Flipflop.auto_delius_import? ||
      (ENV['AUTO_DELIUS_IMPORT'] || '').split(',').include?(prison)
  end

  def format_email(email)
    if email.nil?
      '(email address not found)'
    else
      mail_to(email)
    end
  end
end
