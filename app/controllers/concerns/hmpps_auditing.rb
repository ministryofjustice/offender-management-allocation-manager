# frozen_string_literal: true

# Audits every request to a controller action declared as audited in config/hmpps_audit.yml.
# When auditing is enabled, requests to actions that aren't declared there at all raise.
# The spec for config/hmpps_audit.yml catches these in CI regardless.
# Actions can call `audit` to add details only they know, or a specific failure reason;
# otherwise the outcome is inferred from the response.
#
module HmppsAuditing
  extend ActiveSupport::Concern

  included do
    # Wraps authorisation and loading callbacks as well as the action and rendering
    prepend_around_action :audit_request
  end

private

  # `details` are sent on the outcome event
  # `failure` makes the outcome a failure with that reason
  def audit(details: nil, failure: nil)
    @audit_interaction&.add_details(details) if details
    @audit_failure_reason = failure if failure
  end

  def audit_request
    return yield unless FeatureFlags.hmpps_audit.enabled?

    config = HmppsAudit::Actions.find(controller_path, action_name)
    return yield unless config

    identity = sso_identity
    return yield if identity.absent? || identity.session_expired?

    @audit_interaction = HmppsAudit::Interaction.new(
      what: config.fetch(:what),
      who: identity.current_user,
      subject_type: config.fetch(:subject_type),
      subject_id: audit_param(config[:subject_id]),
      correlation_id: request.request_id,
      details: audit_query_params(config.fetch(:query_params)),
    )
    @audit_interaction.record do
      yield
      @audit_failure_reason || (generic_audit_failure_reason unless response.successful?)
    end
  end

  def audit_param(key)
    value = params[key] if key
    value.squish.presence if value.is_a?(String)
  end

  def audit_query_params(keys)
    query_params = keys.index_with { audit_param(it) }.compact
    return {} if query_params.empty?

    { 'queryParams' => query_params.transform_keys { it.to_s.camelize(:lower) } }
  end

  def generic_audit_failure_reason
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
    elsif response.unprocessable?
      'Request failed validation'
    else
      'Requested view was not available'
    end
  end
end
