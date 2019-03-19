module ApplicationHelper
  def replace_param(name, value)
    uri = URI.parse(request.original_url)

    query = Rack::Utils.parse_query(uri.query)
    query[name] = value

    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end

  def format_date(date_obj)
    return '' if date_obj.nil?

    date_obj.strftime('%d/%m/%Y')
  end

  def format_date_string(date_string)
    return '' if date_string.empty?

    Date.parse(date_string).strftime('%d/%m/%Y')
  end

  def pom_level(level)
    {
      'PO' => 'Prison POM',
      'PRO' => 'Probation POM'
    }[level]
  end

  def override_reason_contains(override, val)
    override.override_reasons.present? && override.override_reasons.include?(val)
  end

  def service_provider_label(provider)
    {
      'CRC' => 'Community Rehabilitation Company (CRC)',
      'NPS' => 'National Probation Service (NPS)'
    }[provider]
  end

  def working_pattern_name(pattern)
    return 'Full time' if pattern.to_f == 1.0

    'Part time'
  end

  def pom_responsibility_label(offender)
    ResponsibilityService.new.calculate_pom_responsibility(offender)
  end

  def responsibility_label(offender_responsibility)
    {
      'Probation' => 'Community',
      'Prison' => 'Custody'
    }[offender_responsibility]
  end
end
