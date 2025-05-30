sso_client_secret = Rails.configuration.hmpps_oauth_client_secret
sso_client_id = Rails.configuration.hmpps_oauth_client_id
sso_host = Rails.configuration.nomis_oauth_host

unless sso_client_secret && sso_client_id && sso_host
  $stdout.puts '[WARN] HMPPS_OAUTH_CLIENT_ID, HMPPS_OAUTH_CLIENT_SECRET or NOMIS_OAUTH_HOST not configured'
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :hmpps_sso,
    sso_client_id,
    sso_client_secret,
    client_options: {
      site: sso_host,
      authorize_url: '/auth/oauth/authorize',
      token_url: '/auth/oauth/token'
    })
end
