require 'health'

config = Rails.configuration
config.health_checks = Health.new(timeout_in_seconds_per_check: 2, num_retries_per_check: 2)
  .add_check(
    name: 'db',
    get_response: -> { ActiveRecord::Base.connection.active? },
    check_response: ->(response) { response == true })
  .add_check(
    name: 'prisonApi',
    get_response: -> { HmppsApi::Client.new(config.prison_api_host).get('/health/ping') })
  .add_check(
    name: 'prisonerSearchApi',
    get_response: -> { HmppsApi::Client.new(config.prisoner_search_host).get('/health/ping') })
  .add_check(
    name: 'communityApi',
    get_response: -> { HmppsApi::Client.new(config.community_api_host).get('/health/ping') })
  .add_check(
    name: 'complexityOfNeedsApi',
    get_response: -> { HmppsApi::Client.new(config.complexity_api_host).raw_get('/health') },
    check_response: ->(response) { response == 'pong' })
  .add_check(
    name: 'dpsFrontendComponentsApi',
    get_response: -> { HmppsApi::Client.new(config.dps_frontend_components_api_host).get('/ping') })
  .add_check(
    name: 'keyworkerApi',
    get_response: -> { HmppsApi::Client.new(config.keyworker_api_host).get('/health/ping') })
  .add_check(
    name: 'managePomCasesAndDeliusApi',
    get_response: -> { HmppsApi::Client.new(config.manage_pom_cases_and_delius_host).get('/health/ping') })
  .add_check(
    name: 'hmppsAuth',
    get_response: -> { HmppsApi::Client.new(config.nomis_oauth_host).raw_get('/auth/ping') },
    check_response: ->(response) { response == 'pong' })
  .add_check(
    name: 'tieringApi',
    get_response: -> { HmppsApi::Client.new(config.tiering_api_host).get('/health/ping') })
  .add_check(
    name: 'assessRisksAndNeedsApi',
    get_response: -> { HmppsApi::Client.new(config.tiering_api_host).get('/health/ping') })