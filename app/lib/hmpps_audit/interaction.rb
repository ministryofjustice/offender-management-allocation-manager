# frozen_string_literal: true

class HmppsAudit::Interaction
  module OUTCOME
    ATTEMPT = 'ATTEMPT'
    SUCCESS = 'SUCCESS'
    FAILURE = 'FAILURE'
  end

  def initialize(what:, who:, subject_type:, subject_id:, correlation_id:, details: {}, client: HmppsAudit::Client.new)
    @what = what
    @attributes = { who:, subject_type:, subject_id:, correlation_id:, details: }
    @client = client
  end

  # The block returns nil on success, or a safe failure reason for a handled outcome
  def record
    publish(OUTCOME::ATTEMPT)

    # Only application failures belong to the interaction's failure outcome
    # Delivery failures must not turn a successful operation into a failure event
    begin
      failure_reason = yield
    rescue StandardError => e
      record_exception(e)
      raise
    else
      publish(failure_reason ? OUTCOME::FAILURE : OUTCOME::SUCCESS, failure_reason:)
    end
  end

private

  def record_exception(error)
    reason = if error.is_a?(ActiveRecord::RecordNotFound)
               'Resource not found'
             else
               "Application failed to complete the operation: #{error.class.name}"
             end
    publish(OUTCOME::FAILURE, failure_reason: reason)
  end

  def publish(outcome, failure_reason: nil)
    details = @attributes.fetch(:details)
    details = details.merge('failureReason' => failure_reason) if failure_reason

    @client.publish(
      **@attributes, what: "#{@what}_#{outcome}", details:
    )
  rescue StandardError => e
    Rails.error.report(
      e, handled: true, severity: :error, source: 'hmpps_audit',
         context: { what: "#{@what}_#{outcome}", correlation_id: @attributes[:correlation_id] }
    )
  end
end
