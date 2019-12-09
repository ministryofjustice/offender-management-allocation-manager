module ApiHelper
  def stub_offender(nomis_id, booking_number: 754_165, imprisonment_status: 'SENT03')
    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/prisoners/#{nomis_id}").
      to_return(status: 200, body: [{ offenderNo: nomis_id,
                                      gender: 'Male',
                                      convictedStatus: 'Convicted',
                                      latestBookingId: booking_number,
                                      imprisonmentStatus: imprisonment_status }].to_json)

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/offender-sentences/bookings").
      with(
        body: [booking_number].to_json
      ).
      to_return(status: 200, body: [{ offenderNo: nomis_id, bookingId: booking_number, sentenceDetail: {} }].to_json)

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/offender-assessments/CATEGORY").
      with(
        body: [nomis_id].to_json
      ).
      to_return(status: 200, body: {}.to_json)

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/bookings/#{booking_number}/mainOffence").
      to_return(status: 200, body: {}.to_json)
  end

  def stub_poms(prison, poms)
    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/roles/#{prison}/role/POM").
      with(
        headers: {
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        }).
      to_return(status: 200, body: poms.to_json)
    poms.each do |pom|
      stub_pom_emails(pom.staffId, pom.emails)
    end
  end

  def stub_pom_emails(staff_id, emails)
    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/#{staff_id}/emails").
      to_return(status: 200, body: emails.to_json)
  end

  def stub_signed_in_pom(staff_id, username)
    stub_auth_token
    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/#{username}").
      to_return(status: 200, body: { 'staffId': staff_id }.to_json)
  end

  def stub_offenders_for_prison(prison, offenders, bookings)
    # Stub the call to get_offenders_for_prison. Takes a list of offender hashes (in nomis camelCase format) and
    # a list of bookings (same key format). It it your responsibility to make sure they contain the data you want
    # and if you provide a booking, that the id matches between the offender and booking hashes.
    elite2api = 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api'
    elite2listapi = "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true"
    elite2bookingsapi = "#{elite2api}/offender-sentences/bookings"

    # Stub the call that will get the total number of records
    stub_request(:get, elite2listapi).to_return(
      status: 200,
      body: {}.to_json,
      headers: { 'Total-Records' => offenders.count.to_s }
    )

    # Return the actual offenders from the call to /locations/description/PRISON/inmates
    stub_request(:get, elite2listapi).with(
      headers: {
        'Page-Limit' => '200',
        'Page-Offset' => '0'
      }).to_return(status: 200, body: offenders.to_json)

    # Get the booking ids provided
    booking_ids = bookings.map{ |h| h[:bookingId] }.compact
    stub_request(:post, elite2bookingsapi).with(body: booking_ids.to_json).
      to_return(status: 200, body: bookings.to_json, headers: {})
  end

  def stub_multiple_offenders(offenders, bookings)
    elite2api = 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api'
    elite2listapi = "#{elite2api}/prisoners"
    elite2bookingsapi = "#{elite2api}/offender-sentences/bookings"

    stub_request(:post, elite2listapi).to_return(
      status: 200,
      body: offenders.to_json
    )

    # Get the booking ids provided and add a non-existent booking in
    # case none were provided
    stub_request(:post, elite2bookingsapi).
      to_return(status: 200, body: bookings.to_json, headers: {})
  end
end
