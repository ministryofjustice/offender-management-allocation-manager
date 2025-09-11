# frozen_string_literal: true

module ApiHelper
  AUTH_HOST = Rails.configuration.nomis_oauth_host
  T3 = "#{Rails.configuration.prison_api_host}/api".freeze
  T3_SEARCH = Rails.configuration.prisoner_search_host
  NOMIS_USER_ROLES_API_HOST = Rails.configuration.nomis_user_roles_api_host
  ASSESS_RISKS_AND_NEEDS_API_HOST = Rails.configuration.assess_risks_and_needs_api_host
  MANAGE_POM_CASES_AND_DELIUS_HOST = Rails.configuration.manage_pom_cases_and_delius_host
  KEYWORKER_API_HOST = ENV.fetch('KEYWORKER_API_HOST')
  T3_LATEST_MOVE_URL = "#{T3}/movements/offenders?latestOnly=true&movementTypes=TAP".freeze
  T3_BOOKINGS_URL = "#{T3}/offender-sentences/bookings".freeze

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

    # RoSH summary
    stub_request(:get, Addressable::Template.new("#{Rails.configuration.assess_risks_and_needs_api_host}/risks/crn/{crn}/summary"))
      .to_return(body: {}.to_json)

    # Alerts
    stub_request(:get, "#{Rails.configuration.prison_alerts_api_host}/prisoners/#{offender_no}/alerts")
      .to_return(body: { content: [] }.to_json)

    stub_sentence_terms(offender)

    stub_oasys_assessments(offender_no)
  end

  def stub_sentence_terms(offender)
    # Offender Sentence and Terms
    booking_id = offender.fetch(:bookingId)
    stub_request(:get, "#{T3}/offender-sentences/booking/#{booking_id}/sentenceTerms").to_return(body: [].to_json)
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
      stub_filtered_pom(prison, pom)
    end
  end

  def stub_filtered_pom(prison, pom)
    pom.agencyId = prison

    stub_request(:get, "#{T3}/staff/roles/#{prison}/role/POM")
      .with(
        query: {
          staffId: pom.staffId
        },
        headers: {
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        })
      .to_return(body: [pom].to_json)

    stub_pom(pom)
  end

  def stub_inexistent_filtered_pom(prison, nomis_staff_id)
    stub_request(:get, "#{T3}/staff/roles/#{prison}/role/POM")
      .with(
        query: {
          staffId: nomis_staff_id
        },
        headers: {
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        })
      .to_return(body: [].to_json)
  end

  # TODO: this stub will go, keeping it for now for compatibility
  def stub_pom_emails(staff_id, emails)
    stub_pom(
      build(:pom, staffId: staff_id, primaryEmail: emails.first)
    )
  end

  def stub_pom(pom)
    stub_request(:get, "#{NOMIS_USER_ROLES_API_HOST}/users/staff/#{pom.staffId}")
      .to_return(body: pom.to_json)
  end

  def stub_user(username, staff_id, **attributes)
    stub_request(:get, "#{NOMIS_USER_ROLES_API_HOST}/users/#{username}")
      .to_return(body: {
        'staffId': staff_id,
        'username': username,
        'firstName': attributes.fetch(:firstName, 'MOIC'),
        'lastName': attributes.fetch(:lastName, 'POM'),
        'primaryEmail': attributes.fetch(:primaryEmail, 'user@example.com'),
        'activeCaseloadId': attributes.fetch(:activeCaseloadId, 'LEI')
      }.to_json)
  end

  def stub_signed_in_pom(prison, staff_id, username = 'alice')
    stub_sso_data(prison, staff_id:, username:, roles: [SsoIdentity::POM_ROLE])
    stub_user(username, staff_id)
  end

  def stub_signed_in_spo_pom(prison, staff_id, username = 'alice')
    stub_sso_data(prison, staff_id:, username:, roles: [SsoIdentity::POM_ROLE, SsoIdentity::SPO_ROLE])
    stub_user(username, staff_id)
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

    stub_prison_timeline

    # Remove offenders with unwanted legal statuses – the following APIs are only called/stubbed for filtered offender IDs
    filtered_offenders = HmppsApi::PrisonApi::OffenderApi.filtered_offenders(offenders.map(&:with_indifferent_access))
    stub_offender_categories(filtered_offenders)

    allow(HmppsApi::ComplexityApi).to receive(:get_complexities)
                                        .with(filtered_offenders.map { |o| o.fetch(:prisonerNumber) })
                                        .and_return(filtered_offenders.map { |o| [o.fetch(:prisonerNumber), o.fetch(:complexityLevel)] }.to_h)

    filtered_offenders.each { |o| stub_offender(o) }

    stub_movements(movements)
  end

  def stub_prison_timeline
    stub_request(:get, Addressable::Template.new("#{T3}/offenders/{id}/prison-timeline"))
      .to_return(
        status: 200,
        body: {
          "prisonPeriod" => [
            { 'prisons' => ['ABC', 'DEF'] }
          ]
        }.to_json)
  end

  def stub_oasys_assessments(offender_no)
    stub_request(:get, "#{ASSESS_RISKS_AND_NEEDS_API_HOST}/assessments/timeline/nomisId/#{offender_no}")
      .to_return(body: { 'timeline': [] }.to_json)
  end

  def stub_risk_and_needs(crn, response_body = '{"summary": {}}')
    stub_request(:get, "https://assess-risks-and-needs-dev.hmpps.service.justice.gov.uk/risks/crn/#{crn}")
      .to_return(status: 200, body: response_body, headers: {})
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

  def stub_keyworker(prison_code, offender_id, keyworker = '{}')
    stub_request(:get, "#{KEYWORKER_API_HOST}/key-worker/#{prison_code}/offender/#{offender_id}")
      .to_return(body: keyworker.to_json)
  end

  # Stubs every CRN
  def stub_community_offender(_nomis_offender_id = nil, _community_data = nil)
    stub_request(:get, Addressable::Template.new("#{MANAGE_POM_CASES_AND_DELIUS_HOST}/case-records/{crn}/risks/mappa"))
        .to_return(body: { "category" => 3, "level" => 1, "reviewDate" => "2021-04-27", "startDate" => "2021-01-27" }.to_json)
  end

  # Stubs a specific CRN only
  def stub_specific_community_offender(crn = nil, community_data = nil)
    community_data ||= { "category" => 3, "level" => 1, "reviewDate" => "2021-04-27", "startDate" => "2021-01-27" }
    stub_request(:get, "#{MANAGE_POM_CASES_AND_DELIUS_HOST}/case-records/#{crn}/risks/mappa")
        .to_return(body: community_data.to_json)
  end

  def stub_agencies(type)
    stub_request(:get, "https://prison-api-dev.prison.service.justice.gov.uk/api/agencies/type/#{type}")
      .to_return(body: [{ 'agencyId' => 'HOS1', 'description' => 'Hospital One', 'active' => 1 }].to_json)
  end

  def stub_bank_holidays
    stub_request(:get, BankHolidays::API_URL).to_return(body: {}.to_json)
  end

private

  def search_api_response(offender)
    offender.except(:complexityLevel, :category)
  end
end
