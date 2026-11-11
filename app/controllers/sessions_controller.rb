# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    identity = SignonIdentity.from_omniauth(request.env['omniauth.auth'])
    return redirect_to root_url unless identity

    HmppsAudit::Interaction.new(
      what: 'AUTH_USER_SIGN_IN', who: identity.username,
      subject_type: 'NOT_APPLICABLE', subject_id: nil, correlation_id: request.request_id
    ).record do
      redirect_path = session[:redirect_path] || root_url

      # Root clears SSO data to refresh it but this callback has already fetched fresh data,
      # so there is no need to redirect twice, we can skip directly to the dashboard here
      if [root_path, root_url].include?(redirect_path) && identity.active_caseload.present?
        redirect_path = prison_dashboard_index_path(identity.active_caseload)
      end

      reset_session_preserving_flash
      save_to_session(:sso_data, identity)

      redirect_to redirect_path
      nil
    end
  end

  def destroy
    reset_session
    redirect_to sso_signout_url, allow_other_host: true
  end

  def failure
    render(status: :unauthorized)
  end

private

  def reset_session_preserving_flash
    messages = flash.to_hash
    reset_session
    flash.update(messages)
  end

  def sso_signout_url
    url = URI.parse("#{Rails.configuration.nomis_oauth_host}/auth/logout")
    url.query = {
      redirect_uri: Rails.configuration.allocation_manager_host,
      client_id: Rails.configuration.hmpps_oauth_client_id
    }.to_query

    url.to_s
  end
end
