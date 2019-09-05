# frozen_string_literal: true

module PageHelper
  # rubocop:disable Metrics/LineLength
  def back_link(class_name = 'govuk-back-link govuk-!-margin-top-0 govuk-!-margin-bottom-6')
    if request.env['HTTP_REFERER'].present? &&
        request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      link_to('Back', :back, class: class_name)
    else
      link_to('Back', root_path, class: class_name)
    end
  end
  # rubocop:enable Metrics/LineLength

  def class_type(contact_errors)
    if contact_errors.present?
      'govuk-form-group govuk-form-group--error'
    else
      'govuk-form-group'
    end
  end
end
