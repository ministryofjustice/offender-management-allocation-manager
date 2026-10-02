# frozen_string_literal: true

class SignificantChanges
  # Detects a recalculated handover date moving beyond the upcoming handover
  # window, and the recommended POM now differs to the allocated POM
  class HandoverDetector < Detector
    tracks :handover, label: 'Handover date', item_type: 'CalculatedHandoverDate', attribute: 'handover_date'

    def change
      latest_date = timeline.last&.fetch(:to)
      return unless latest_date && outside_window?(latest_date, Time.zone.today)

      transition = timeline.reverse.find do |entry|
        entry[:from] && entry[:to] &&
          !outside_window?(entry[:from], entry[:at].to_date) &&
          outside_window?(entry[:to], entry[:at].to_date)
      end
      return unless transition && review.recommendation_differs_from_allocation?

      Change.new(type:, label:, from_value: transition[:from], to_value: latest_date, changed_at: transition[:at])
    end

  private

    def outside_window?(handover_date, relative_to_date)
      handover_date > relative_to_date + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION
    end
  end
end
