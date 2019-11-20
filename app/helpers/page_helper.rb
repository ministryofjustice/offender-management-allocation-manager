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

  def field_error(errors, field)
    if errors.present? && errors[field].present?
      'govuk-form-group govuk-form-group--error'
    else
      'govuk-form-group'
    end
  end

  def field_element_error(errors, field, class_value)
    if errors.present? && errors[field].present?
      class_value + " #{class_value}--error"
    else
      class_value
    end
  end
end
