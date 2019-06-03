# frozen_string_literal: true

module SortHelper
  # rubocop:disable Rails/HelperInstanceVariable
  class Sorter
    include ActionView::Helpers::TagHelper

    DEFAULT_SORT = 'last_name'

    def initialize(url)
      @uri = URI.parse(url)

      @query = Rack::Utils.parse_query(@uri.query)
      @current_sort_field = @query['sort']
    end

    def link_for_field(field_name)
      if @current_sort_field.present? && @current_sort_field.start_with?(field_name)
        # Check if name is already in query, and invert the search if it is
        @query['sort'] = "#{field_name} #{invert_sort_parameter(@current_sort_field)}"
      else
        # If it isn't, choose the appropriate default
        @query['sort'] = "#{field_name} #{default_direction(field_name)}"
      end

      @uri.query = Rack::Utils.build_query(@query)
      @uri.to_s
    end

    def arrow_for_field(field_name)
      if field_name == DEFAULT_SORT && @current_sort_field.blank?
        return asc_tag
      end

      return '' if @current_sort_field.blank?
      return '' unless @current_sort_field.start_with?(field_name)

      if @current_sort_field.end_with?('asc')
        asc_tag
      else
        desc_tag
      end
    end

  private

    def default_direction(field_name)
      return 'desc' if @current_sort_field.blank? && field_name == DEFAULT_SORT

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
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def sort_link(field_name)
    sorter.link_for_field(field_name)
  end

  def sort_arrow(field_name)
    sorter.arrow_for_field(field_name)
  end

private

  # rubocop:disable Rails/HelperInstanceVariable
  def sorter
    @sorter ||= Sorter.new(request.original_url)
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
