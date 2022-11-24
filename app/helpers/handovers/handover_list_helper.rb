module Handovers
  module HandoverListHelper
    def handover_list_table(headers:,
                            table_class: [],
                            &block)
      thead = handover_list_thead(headers)
      tbody = tag.tbody(class: 'govuk-table__body') { capture(&block) }
      tag.table(class: ['govuk-table'] + table_class,
                data: { module: 'moj-sortable-table' }) do
        thead + tbody
      end
    end

  private

    def handover_list_thead(headers)
      tag.thead(class: 'govuk-table__head') do
        tag.tr(class: 'govuk-table__row') do
          headers.each_with_index.map { |hcol, index| handover_list_th(hcol, index) }.join("\n").html_safe
        end
      end
    end

    def handover_list_th(col, index)
      th_class = ['govuk-table__header'] + col.fetch(:class, [])
      tag.th(scope: 'col', class: th_class, 'aria-sort': col.fetch(:sort, 'none')) do
        if col[:type] == 'button'
          tag.button(type: 'button', data: { index: index.to_s }) { col.fetch(:body) }
        else
          col.fetch(:body)
        end
      end
    end
  end
end
