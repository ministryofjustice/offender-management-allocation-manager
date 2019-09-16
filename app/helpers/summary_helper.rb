# frozen_string_literal: true

module SummaryHelper
  def start_date(prison_dates, offender_no)
    prison_date = prison_dates.detect{ |f| f[:offender_no] == offender_no }
    prison_date.nil? ? '-1' : prison_date[:days_count]
  end
end
