# frozen_string_literal: true

module PageHelper
  def back_link(class_name = 'govuk-back-link govuk-!-margin-top-0 govuk-!-margin-bottom-6')
    if request.env['HTTP_REFERER'].present? &&
        request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      link_to('Back', :back, class: class_name)
    else
      link_to('Back', root_path, class: class_name)
    end
  end

  def pom_profile_back_link(prison:, pom:, class_name: 'govuk-back-link govuk-!-margin-top-0 govuk-!-margin-bottom-6')
    link_to('Back', pom_profile_back_path(prison:, pom:), class: class_name)
  end

  def field_error(errors, field)
    if errors.present? && errors[field].present?
      'govuk-form-group govuk-form-group--error'
    else
      'govuk-form-group'
    end
  end

private

  def pom_profile_back_path(prison:, pom:)
    fallback_path = prison_poms_path(prison.code)
    pom_base_path = prison_pom_path(prison.code, nomis_staff_id: pom.staff_id)
    referer_path  = normalised_internal_path(request.referer)

    return fallback_path if referer_path.blank?
    return fallback_path if referer_path == request.fullpath
    return fallback_path if referer_path.start_with?(pom_base_path)

    referer_path
  end

  def normalised_internal_path(url)
    return if url.blank?

    uri = URI.parse(url)
    return if uri.scheme.present? && !%w[http https].include?(uri.scheme)
    return if uri.host.present? && uri.host != request.host
    return if uri.port.present? && uri.port != request.port

    path = uri.path.presence || '/'
    return if !path.start_with?('/') || path.start_with?('//')

    query = uri.query.present? ? "?#{uri.query}" : ''

    "#{path}#{query}"
  rescue URI::InvalidURIError
    nil
  end
end
