# frozen_string_literal: true

module HmppsAuditing
  extend ActiveSupport::Concern

  class_methods do
    def audit_action(action, what:, subject_type:, subject_id:, success: -> { response.successful? }, failure_reason: nil)
      # Wrap authorisation and loading callbacks as well as the action and rendering
      prepend_around_action(only: action) do |controller, operation|
        controller.send(:audit_user_action, what:, subject_type:, subject_id:, success:, failure_reason:, &operation)
      end
    end
  end

private

  def audit_user_action(what:, subject_type:, subject_id:, success:, failure_reason:)
    return yield unless FeatureFlags.hmpps_audit.enabled?

    identity = sso_identity
    return yield if identity.absent? || identity.session_expired?

    interaction = HmppsAudit::Interaction.new(
      what:,
      who: identity.current_user,
      subject_type:,
      subject_id: instance_exec(&subject_id),
      correlation_id: request.request_id,
    )
    interaction.record do
      yield
      unless instance_exec(&success)
        (instance_exec(&failure_reason) if failure_reason) || audit_failure_reason
      end
    end
  end

  def audit_failure_reason
    if response.redirect?
      case URI.parse(response.location).path
      when '/401' then 'User does not have access to this data'
      when '/404' then 'Resource not found'
      else 'Request redirected before completing the operation'
      end
    elsif response.forbidden? || response.unauthorized?
      'User does not have access to this data'
    elsif response.not_found?
      'Resource not found'
    else
      'Requested view was not available'
    end
  end
end
