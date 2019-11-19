# frozen_string_literal: true

module SummaryHelper
  def delius_schedule_for(arrival_date)
    return 'Monday' if Time.zone.today.on_weekend?
    return 'Tomorrow' if arrival_date == Time.zone.today

    'Today'
  end
end
