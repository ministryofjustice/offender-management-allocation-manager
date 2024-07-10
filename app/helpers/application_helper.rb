# frozen_string_literal: true

module ApplicationHelper
  def format_date(date_obj, replacement: '')
    if date_obj
      date_obj.to_fs(:rfc822)
    else
      replacement
    end
  end

  def format_date_long(date_obj)
    "#{date_obj.strftime("#{date_obj.day.ordinalize} %B %Y")} (#{date_obj.strftime('%R')})"
  end

  def format_time_readably(time)
    time.strftime('%-d %b %Y %H:%M')
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
    }[level]
  end

  def handover_type_label(offender)
    case offender.handover_type
    when 'standard' then t('handover_type.standard')
    when 'enhanced' then t('handover_type.enhanced')
    when 'none' then t('handover_type.none')
    when 'missing' then t('handover_type.missing')
    else raise(ArgumentError,
               "INVALID value: Offender(#{offender.nomis_offender_id})#handover_type = #{offender.handover_type}")
    end
  end

  def working_pattern_name(pattern)
    return 'Full time' if pattern.to_d == 1.0.to_d

    'Part time'
  end

  def sentence_type_label(offender)
    return 'Indeterminate' if offender.indeterminate_sentence?

    'Determinate'
  end

  def vlo_tag(offender)
    return '' unless offender.active_vlo? || offender.victim_liaison_officers.any?

    tag.span('VLO CONTACT', class: 'govuk-tag govuk-tag--red')
  end

  def humanized_bool(bool_value)
    bool_value ? 'Yes' : 'No'
  end

  def format_email(email)
    if email.nil?
      '(email address not found)'
    else
      mail_to(email)
    end
  end

  def unreverse_name(reversed_name)
    return '' if reversed_name.blank?

    reversed_name.split(',').reverse.join(' ').strip
  end

  def gtm_id
    Rails.configuration.gtm_id
  end
end
