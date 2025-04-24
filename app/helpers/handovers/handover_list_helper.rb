module Handovers
  module HandoverListHelper
    def handover_list_table(headers:,
                            table_class: [],
                            anchor: nil,
                            &block)
      thead = handover_list_thead(headers, anchor)
      tbody = tag.tbody(class: 'govuk-table__body') { capture(&block) }
      tag.table(class: ['govuk-table'] + table_class,
                data: { module: 'moj-sortable-table' }) do
        thead + tbody
      end
    end

    def dps_sentence_and_release_link(offender_no)
      "#{ENV['DIGITAL_PRISON_SERVICE_HOST']}/prisoner/#{offender_no}/sentence-and-release"
    end

  private

    def handover_list_thead(headers, anchor)
      tag.thead(class: 'govuk-table__head') do
        tag.tr(class: 'govuk-table__row') do
          headers.each_with_index.map { |hcol, index| handover_list_th(hcol, index, anchor) }.join("\n").html_safe
        end
      end
    end

    def handover_list_th(col, index, anchor)
      th_class = ['govuk-table__header'] + col.fetch(:class, [])

      attrs = { scope: 'col', class: th_class }
      attrs['aria-sort'] = sort_aria_value(col[:sort]) if col[:sort]

      tag.th(**attrs.compact_blank) do
        if col[:sort]
          link_to(col.fetch(:body), sort_link(col[:sort], anchor: anchor), data: { index: index.to_s }) +
          sort_arrow(col[:sort])
        else
          col.fetch(:body)
        end
      end
    end
  end
end
