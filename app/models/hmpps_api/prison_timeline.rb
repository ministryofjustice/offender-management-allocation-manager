# frozen_string_literal: true

# This model represents a persons journey through their various prison visits - its goal is to tell
# us which prisons they were in and when
module HmppsApi
  class PrisonTimeline
    def initialize(movements)
      # ignore transfers-out - timeline only cares about in transfers
      @movements = movements.reject { |m| m.transfer? && m.out? }.reverse
    end

    def last_movement
      @movements.first
    end

    # represents an Episode/stay in prison. An offender can be in the same prison more
    # than once e.g. Leeds -> Cardiff -> Leeds, so prison_code is not unique
    PrisonEpisode = Struct.new :start_date, :prison_code, keyword_init: true

    # return an prison episode/stay for the specified date/time.
    def prison_episode(date)
      # need to filter out non-prison transfers as we are prison-centric
      relevent_movement = @movements.select(&:to_prison?).detect { |m| m.happened_at <= date }
      PrisonEpisode.new start_date: relevent_movement.movement_date, prison_code: relevent_movement.to_agency
    end
  end
end
