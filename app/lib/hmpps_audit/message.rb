# frozen_string_literal: true

class HmppsAudit::Message
  SUBJECT_TYPES = %w[NOT_APPLICABLE CRN PRISONER_ID SEARCH_TERM USER_ID REPORT_ID].freeze

  attr_reader :what, :correlation_id

  def initialize(what:, who:, subject_type:, subject_id: nil, correlation_id: nil, details: nil)
    validate_string!(:what, what)
    validate_string!(:who, who)
    validate_string!(:subject_id, subject_id) unless subject_id.nil?
    validate_string!(:correlation_id, correlation_id) unless correlation_id.nil?

    raise ArgumentError, 'Unsupported `subject_type`' unless SUBJECT_TYPES.include?(subject_type)
    raise ArgumentError, '`details` must be a Hash' unless details.nil? || details.is_a?(Hash)

    @what = what
    @who = who
    @subject_type = subject_type
    @subject_id = subject_id
    @correlation_id = correlation_id
    @details = details&.to_json
    @timestamp = Time.current.utc.iso8601(3)
  end

  def to_h
    {
      what: @what,
      who: @who,
      subjectType: @subject_type,
      subjectId: @subject_id,
      correlationId: @correlation_id,
      # The audit contract requires JSON encoded inside the outer JSON message
      details: @details,
      when: @timestamp,
      service: Rails.configuration.service_name,
    }.compact
  end

private

  def validate_string!(name, value)
    raise ArgumentError, "`#{name}` must be a String" unless value.is_a?(String)
  end
end
