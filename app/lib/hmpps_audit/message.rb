# frozen_string_literal: true

class HmppsAudit::Message
  SERVICE_NAME = 'offender-management-allocation-manager'

  attr_reader :what, :correlation_id

  def initialize(what:, who:, subject_type: nil, subject_id: nil, correlation_id: nil, details: nil)
    validate_string!(:what, what)
    validate_string!(:who, who)
    validate_string!(:subject_type, subject_type) unless subject_type.nil?
    validate_string!(:subject_id, subject_id) unless subject_id.nil?
    validate_string!(:correlation_id, correlation_id) unless correlation_id.nil?
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
      service: SERVICE_NAME,
    }.compact
  end

private

  def validate_string!(name, value)
    raise ArgumentError, "`#{name}` must be a String" unless value.is_a?(String)
  end
end
