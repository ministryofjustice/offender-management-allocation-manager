# frozen_string_literal: true

module SortHelper
  # rubocop:disable Naming/AccessorMethodName
  def set_search_param(field_name)
    uri = URI.parse(request.original_url)

    query = Rack::Utils.parse_query(uri.query)
    current_sort = query['sort']

    if current_sort.present? && current_sort.start_with?(field_name)
      # Check if name is already in query, and invert the search if it is
      query['sort'] = "#{field_name} #{invert_sort_parameter(current_sort)}"
    else
      # If it isn't, choose the appropriate default
      query['sort'] = "#{field_name} asc"
    end

    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end
  # rubocop:enable Naming/AccessorMethodName

  def display_arrow(field_name)
    uri = URI.parse(request.original_url)

    query = Rack::Utils.parse_query(uri.query)
    current_sort = query['sort']
    return '' unless current_sort.present? && current_sort.start_with?(field_name)

    if current_sort.end_with?('asc')
      content_tag(:span, '&#9650'.html_safe, class: "sort-arrow" )
    else
      content_tag(:span, '&#9660'.html_safe, class: "sort-arrow" )
    end
  end

private

  def invert_sort_parameter(param)
    return 'desc' if param.end_with?('asc')

    'asc'
  end
end
