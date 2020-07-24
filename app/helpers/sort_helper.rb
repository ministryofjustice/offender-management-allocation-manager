# frozen_string_literal: true

module SortHelper
  DEFAULT_SORT = 'last_name'

  def sort_link(field_name)
    link_for_field(field_name, URI.parse(request.original_url))
  end

  def sort_arrow(field_name)
    arrow_for_field(field_name, URI.parse(request.original_url))
  end

private

  def link_for_field(field_name, uri)
    query = Rack::Utils.parse_query(uri.query)
    current_sort_field = query['sort']

    query['sort'] = if current_sort_field.present? && current_sort_field.start_with?(field_name)
                      # Check if name is already in query, and invert the search if it is
                      "#{field_name} #{invert_sort_parameter(current_sort_field)}"
                    else
                      # If it isn't, choose the appropriate default
                      "#{field_name} #{default_direction(field_name, current_sort_field)}"
                    end

    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end

  def arrow_for_field(field_name, uri)
    query = Rack::Utils.parse_query(uri.query)
    current_sort_field = query['sort']

    if field_name == DEFAULT_SORT && current_sort_field.blank?
      return asc_tag
    end

    return '' if current_sort_field.blank?
    return '' unless current_sort_field.start_with?(field_name)

    if current_sort_field.end_with?('asc')
      asc_tag
    else
      desc_tag
    end
  end

  def default_direction(field_name, current_sort_field)
    return 'desc' if current_sort_field.blank? && field_name == DEFAULT_SORT

    'asc'
  end

  def asc_tag
    content_tag(:span, '&#9650'.html_safe, class: 'sort-arrow')
  end

  def desc_tag
    content_tag(:span, '&#9660'.html_safe, class: 'sort-arrow')
  end

  def invert_sort_parameter(param)
    return 'desc' if param.end_with?('asc')

    'asc'
  end
end
