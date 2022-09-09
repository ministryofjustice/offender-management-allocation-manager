module Rules
  class CommunityDateRules
    class << self
      def determinate_nps_community_dates(sentence_start_date:,
                                          conditional_release_date: nil,
                                          automatic_release_date: nil)
        earliest_release_date = [automatic_release_date, conditional_release_date].compact.min
        raise ArgumentError, 'One of conditional or automatic release date required' if earliest_release_date.blank?

        com_responsible_date = earliest_release_date - 7.months - 15.days

        com_responsible_date = sentence_start_date if com_responsible_date < sentence_start_date

        Community::CommunityDates.new(com_allocated_date: com_responsible_date,
                                      com_responsible_date: com_responsible_date)
      end
    end
  end
end
