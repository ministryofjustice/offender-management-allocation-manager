# frozen_string_literal: true

module SortHelper
  DEFAULT_SORT = 'last_name'

  def sort_link(field_name, anchor: nil)
    raise ArgumentError, "`#{field_name}` is not an allowed sortable field" unless sortable_field?(field_name)

    if anchor.nil?
      link_for_field(field_name, URI.parse(request.original_url))
    else
      link_for_field(field_name, URI.parse(request.original_url)) << "##{anchor}"
    end
  end

  def sort_arrow(field_name)
    raise ArgumentError, "`#{field_name}` is not an allowed sortable field" unless sortable_field?(field_name)

    uri = URI.parse(request.original_url)
    query = Rack::Utils.parse_query(uri.query)
    direction = sort_direction_for(field_name, query['sort'])
    direction ? send("#{direction}_tag") : ''
  end

  def sort_aria(field_name)
    raise ArgumentError, "`#{field_name}` is not an allowed sortable field" unless sortable_field?(field_name)

    value = sort_aria_value(field_name)
    value == '' ? '' : "aria-sort=\"#{value}\"".html_safe
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

  def sort_direction_for(field_name, current_sort_field = '')
    if field_name == DEFAULT_SORT && current_sort_field.blank?
      return :asc
    end

    return nil if current_sort_field.blank?
    return nil unless current_sort_field.start_with?(field_name)

    if current_sort_field.end_with?('asc')
      :asc
    else
      :desc
    end
  end

  def sort_aria_value(field_name)
    direction = sort_direction_for(field_name, params['sort'])
    direction ? { asc: 'ascending', desc: 'descending' }[direction] : nil
  end

  def default_direction(field_name, current_sort_field)
    return 'desc' if current_sort_field.blank? && field_name == DEFAULT_SORT

    'asc'
  end

  def asc_tag
    content_tag(:span, '&#9650'.html_safe, class: 'app-sort-arrow')
  end

  def desc_tag
    content_tag(:span, '&#9660'.html_safe, class: 'app-sort-arrow')
  end

  def invert_sort_parameter(param)
    return 'desc' if param.end_with?('asc')

    'asc'
  end

  def sortable_field?(field_name)
    Sorting::SORTABLE_FIELDS.include?(field_name.to_sym)
  end
end
