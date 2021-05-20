# frozen_string_literal: true

module AllocationHelper
  # convert a timeline and sorted history into a set of episodes with prison code and events
  # both the episodes and the events are time-reversed as that is how they are displayed
  def prison_episodes(timeline, history_list)
    history_list.group_by { |history| timeline.prison_episode(history.created_at) }.
      map { |k, v| [k, v.reverse] }.
      sort_by { |k, _v| k.start_date }.
      reverse
  end
end
