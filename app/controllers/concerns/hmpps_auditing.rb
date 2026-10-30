# frozen_string_literal: true

# Audits every request to a controller action declared as audited in config/hmpps_audit.yml.
# When auditing is enabled, requests to actions that aren't declared there at all raise.
# The spec for config/hmpps_audit.yml catches these in CI regardless.
# Actions can call `audit` to add details only they know, or a specific failure reason;
# otherwise the outcome is inferred from the response.
# Controllers can override `entity_for_audit` to add the record's ID to outcome details.
#
module HmppsAuditing
  extend ActiveSupport::Concern

  USER_CANCELLED = 'User cancelled the action'

  included do
    # Wraps authorisation and loading callbacks as well as the action and rendering
    prepend_around_action :audit_request
  end

private

  # Override with the current ActiveRecord entity. Unsaved records and form objects are ignored
  def entity_for_audit = nil

  # `details` are sent on the outcome event
  # `results` are the displayed subject IDs, sent with their count on the outcome event
  # `failure` makes the outcome a failure with that reason
  # `success` allows completed writes to succeed even when followed by a redirect
  def audit(details: nil, results: nil, failure: nil, success: false)
    @audit_interaction&.add_details(details) if details
    @audit_interaction&.add_details('results' => { 'resultCount' => results.size, 'returnedSubjectIds' => results }) if results
    @audit_failure_reason = failure if failure
    @audit_success = true if success
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
      begin
        yield
      ensure
        audit_entity_details
      end
      @audit_failure_reason || (generic_audit_failure_reason unless @audit_success || response.successful?)
    end
  end

  def audit_entity_details
    entity = entity_for_audit
    return unless entity.is_a?(ActiveRecord::Base) && !entity.new_record? && entity.id.present?

    @audit_interaction.add_details('entityId' => entity.id)
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
