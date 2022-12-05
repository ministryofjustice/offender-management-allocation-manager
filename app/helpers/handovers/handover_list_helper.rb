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

    def com_allocation_overdue_days(offender, relative_to_date: Time.zone.now.to_date)
      raise 'COM responsible date not set' unless offender.com_responsible_date

      raise 'COM responsible date is in the future' if offender.com_responsible_date > relative_to_date

      (relative_to_date - offender.com_responsible_date).to_i
    end

    def dps_sentence_and_release_link(offender_or_offender_no)
      offender_or_offender_no = offender_or_offender_no.offender_no unless offender_or_offender_no.is_a?(String)
      "#{ENV['DIGITAL_PRISON_SERVICE_HOST']}/prisoner/#{offender_or_offender_no}/sentence-and-release"
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
