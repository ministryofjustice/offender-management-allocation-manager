# frozen_string_literal: true

module ApiHelper
  AUTH_HOST = Rails.configuration.nomis_oauth_host
  T3 = "#{Rails.configuration.prison_api_host}/api"
  T3_SEARCH = Rails.configuration.prisoner_search_host
  KEYWORKER_API_HOST = ENV.fetch('KEYWORKER_API_HOST')
  COMMUNITY_HOST = "#{Rails.configuration.community_api_host}/secure"
  T3_LATEST_MOVE_URL = "#{T3}/movements/offenders?latestOnly=true&movementTypes=TAP"
  T3_BOOKINGS_URL = "#{T3}/offender-sentences/bookings"
  ASSESSMENT_API_HOST = Rails.configuration.assessment_api_host

  def stub_nil_offender
    stub_request(:post, "#{T3_SEARCH}/prisoner-search/prisoner-numbers").to_return(body: [].to_json).with(query: { 'include-restricted-patients': true })
  end

  def stub_offender(offender)
    offender_no = offender.fetch(:prisonerNumber)

    # Prison Search API
    stub_request(:post, "#{T3_SEARCH}/prisoner-search/prisoner-numbers")
      .with(body: { prisonerNumbers: [offender_no] }.to_json, query: { 'include-restricted-patients': true })
      .to_return(body: [search_api_response(offender)].to_json)

    # This endpoint is only used by HmppsApi::PrisonApi::OffenderApi.get_image
    # to get the "facialImageId" field for an offender.
    # Return an empty response so it falls back to the default offender photo.
    stub_request(:post, "#{T3}/offender-sentences/bookings")
      .with(body: [offender.fetch(:bookingId)].to_json)
      .to_return(body: [{}].to_json)

    stub_offender_categories([offender])

    stub_movements

    stub_request(:get, "#{Rails.configuration.complexity_api_host}/v1/complexity-of-need/offender-no/#{offender_no}")
      .to_return(body: { level: offender.fetch(:complexityLevel) }.to_json)

    stub_oasys_assessments(offender_no)
  end

  def stub_movements(movements = [])
    stub_request(:post, "#{T3}/movements/offenders?movementTypes=ADM&movementTypes=TRN&latestOnly=false")
      .to_return(body: movements.to_json)
    stub_request(:post, "#{T3}/movements/offenders?movementTypes=REL&latestOnly=false")
      .to_return(body: movements.to_json)
    stub_request(:post, T3_LATEST_MOVE_URL)
      .to_return(body: movements.to_json)
  end

  def stub_movements_for(offender_no, movements, movement_types: ['ADM', 'TRN'])
    stub_request(:post, "#{T3}/movements/offenders?#{movement_types.map { |t| "movementTypes=#{t}" }.join('&')}&latestOnly=false&allBookings=true")
      .with(body: [offender_no].to_json)
      .to_return(body: movements.to_json)
  end

  def stub_poms(prison, poms)
    poms.each { |pom| pom.agencyId = prison }

    stub_request(:get, "#{T3}/staff/roles/#{prison}/role/POM")
      .with(
        headers: {
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        })
      .to_return(body: poms.to_json)
    poms.each do |pom|
      stub_pom(pom)
      stub_pom_emails(pom.staffId, pom.emails)
    end
  end

  def stub_pom_emails(staff_id, emails)
    stub_request(:get, "#{T3}/staff/#{staff_id}/emails")
      .to_return(body: emails.to_json)
  end

  def stub_pom(pom)
    stub_request(:get, "#{T3}/staff/#{pom.staffId}")
      .to_return(body: pom.to_json)
  end

  def stub_signed_in_pom(prison, staff_id, username = 'alice')
    stub_auth_token
    stub_sso_data(prison, username: username, roles: [SsoIdentity::POM_ROLE])
    stub_request(:get, "#{T3}/users/#{username}")
      .to_return(body: { 'staffId': staff_id }.to_json)
  end

  def stub_signed_in_spo_pom(prison, staff_id, username = 'alice')
    stub_auth_token
    stub_sso_data(prison, username: username, roles: [SsoIdentity::POM_ROLE, SsoIdentity::SPO_ROLE])
    stub_request(:get, "#{T3}/users/#{username}")
        .to_return(body: { 'staffId': staff_id }.to_json)
  end

  def stub_offenders_for_prison(prison, offenders, movements = [])
    # Put all offenders in the specified prison
    offenders.each { |offender| offender[:prisonId] = prison }

    # Prison Search API
    stub_request(:get, "#{T3_SEARCH}/prisoner-search/prison/#{prison}").with(query: hash_including(:page, :size, 'include-restricted-patients'))
      .to_return(body: {
        content: offenders.map { |o| search_api_response(o) },
        last: true,
        totalPages: 1
      }.to_json)

    # Prison timeline
    stub_request(:get, "#{T3}/offenders/T0000AA/prison-timeline")
      .to_return(
        status: 200,
        body: {
          "prisonPeriod"=> [
            { 'prisons' => ['ABC', 'DEF'] }
          ]
        }.to_json)

    # Remove offenders with unwanted legal statuses – the following APIs are only called/stubbed for filtered offender IDs
    filtered_offenders = offenders.select { |o| HmppsApi::PrisonApi::OffenderApi::ALLOWED_LEGAL_STATUSES.include?(o.fetch(:legalStatus)) }
    stub_offender_categories(filtered_offenders)
    allow(HmppsApi::ComplexityApi).to receive(:get_complexities)
                                        .with(filtered_offenders.map { |o| o.fetch(:prisonerNumber) })
                                        .and_return(filtered_offenders.map { |o| [o.fetch(:prisonerNumber), o.fetch(:complexityLevel)] }.to_h)

    filtered_offenders.each { |o| stub_offender(o) }

    stub_movements(movements)
  end

  def stub_oasys_assessments(offender_no)
    stub_request(:get, "#{ASSESSMENT_API_HOST}/offenders/nomisId/#{offender_no}/assessments/summary?assessmentStatus=COMPLETE")
      .to_return(body: [].to_json)
  end

  def stub_multiple_offenders(offenders, bookings)
    stub_request(:post, "#{T3}/prisoners").to_return(
      body: offenders.to_json
    )

    stub_request(:post, T3_BOOKINGS_URL)
      .to_return(body: bookings.to_json)
  end

  def stub_offender_categories(offenders)
    offender_nos = offenders.map { |offender| offender.fetch(:prisonerNumber) }
    categories = offenders.reject { |offender| offender[:category].nil? }
                          .map do |offender|
                            offender.fetch(:category).merge(offenderNo: offender.fetch(:prisonerNumber))
                          end

    stub_request(:post, "#{T3}/offender-assessments/CATEGORY?activeOnly=true&latestOnly=true&mostRecentOnly=true")
      .with(body: offender_nos.to_json)
      .to_return(body: categories.to_json)
  end

  # Stub an 'empty' response from the Prison Search API, indicating that the offender does not exist in NOMIS
  def stub_non_existent_offender(offender_no)
    stub_request(:post, "#{T3_SEARCH}/prisoner-search/prisoner-numbers")
      .with(body: { prisonerNumbers: [offender_no] }.to_json, query: { 'include-restricted-patients': true })
      .to_return(body: [].to_json)
  end

  def stub_keyworker(prison_code, offender_id, keyworker)
    stub_request(:get, "#{KEYWORKER_API_HOST}/key-worker/#{prison_code}/offender/#{offender_id}")
      .to_return(body: keyworker.to_json)
  end

  def stub_community_offender(nomis_offender_id, community_data, registrations = [])
    stub_request(:get, "#{COMMUNITY_HOST}/offenders/nomsNumber/#{nomis_offender_id}/all")
        .to_return(body: community_data.to_json)
    stub_request(:get, "#{COMMUNITY_HOST}/offenders/nomsNumber/#{nomis_offender_id}/registrations")
        .to_return(body: { registrations: registrations }.to_json)
    stub_request(:get, "#{COMMUNITY_HOST}/offenders/nomsNumber/#{nomis_offender_id}/risk/resourcing/latest")
        .to_return(body: community_data.slice(:enhancedResourcing).to_json)
  end

  def stub_get_all_offender_managers(nomis_offender_id, stubbed_data)
    stub_request(:get, "#{COMMUNITY_HOST}/offenders/nomsNumber/#{nomis_offender_id}/allOffenderManagers")
      .to_return(body: stubbed_data.to_json)
  end

  def stub_resourcing_404(nomis_offender_id)
    stub_request(:get, "#{COMMUNITY_HOST}/offenders/nomsNumber/#{nomis_offender_id}/risk/resourcing/latest")
      .to_return(status: 404)
  end

  def stub_agencies(type)
    stub_request(:get, "https://api-dev.prison.service.justice.gov.uk/api/agencies/type/#{type}")
      .to_return(body: [{ 'agencyId' => 'HOS1', 'description' => 'Hospital One', 'active' => 1 }].to_json)
  end

private

  def search_api_response(offender)
    offender.except(:complexityLevel, :category)
  end
end
