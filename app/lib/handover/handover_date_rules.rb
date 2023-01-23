module Handover
  class HandoverDateRules
    class << self
      def calculate_handover_dates(nomis_offender_id:,
                                   sentence_start_date:,
                                   conditional_release_date: nil,
                                   automatic_release_date: nil)
        earliest_release_date = [automatic_release_date, conditional_release_date].compact.min
        if earliest_release_date.blank?
          raise Handover::HandoverDateCalculationError.new(
            'conditional_release_date, and automatic_release_date are all blank',
            nomis_offender_id: nomis_offender_id)
        end

        handover_date = earliest_release_date - 7.months - 15.days

        handover_date = sentence_start_date if handover_date < sentence_start_date

        HandoverDates.new(handover_date: handover_date,
                          reason: :nps_determinate)
      end
    end
  end
end
