# frozen_string_literal: true

# Remembers where a multi-step journey was started from, so the user can be
# returned there once the journey completes successfully.
#
# Only allowlisted source tokens are stored, scoped to journey, prison and
# offender, and these resolve to server-generated paths.
#
module JourneyReturn
  SESSION_KEY = 'journey_sources'
  SOURCE_TTL = 30.minutes

  # Each source builds its path in the controller context, receiving the prison
  # and offender the journey is scoped to. Ignore unneeded keywords with `**`
  SOURCE_PATHS = {
    'review_allocations' => ->(prison_id:, **) { review_allocations_prison_prisoners_path(prison_id) },
  }.freeze

private

  # Stores where the journey started, if `source` is allowlisted. Unknown
  # sources are ignored so the journey falls back to its default destination
  def remember_journey_source(journey, offender_id:, source: params[:from])
    source = source.to_s
    return unless SOURCE_PATHS.key?(source)

    sources = unexpired_journey_sources
    sources[journey_source_key(journey, offender_id)] = { 'source' => source, 'expires_at' => SOURCE_TTL.from_now.to_i }
    session[SESSION_KEY] = sources
  end

  # Returns the path for the remembered source, or `default` if there isn't one
  # (or it has expired). The source is forgotten so it's only used once
  def stored_journey_path_for(journey, offender_id:, default:)
    sources = unexpired_journey_sources
    entry = sources.delete(journey_source_key(journey, offender_id))
    session[SESSION_KEY] = sources

    path_builder = SOURCE_PATHS[entry&.fetch('source')]
    return default unless path_builder

    instance_exec(prison_id: active_prison_id, offender_id:, &path_builder)
  end

  # Session entries that haven't expired. Expired ones are dropped from the
  # session on the next write
  def unexpired_journey_sources
    now = Time.current.to_i
    (session[SESSION_KEY] || {}).select { |_key, entry| entry['expires_at'].to_i > now }
  end

  def journey_source_key(journey, offender_id)
    [journey, active_prison_id, offender_id].join(':')
  end
end
