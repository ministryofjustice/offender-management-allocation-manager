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

private

  def invert_sort_parameter(param)
    return 'desc' if param.end_with?('asc')

    'asc'
  end
end
