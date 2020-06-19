# frozen_string_literal: true

module ApiHelper
  T3 = 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api'

  def stub_offender(nomis_id, booking_number: 754_165, imprisonment_status: 'SENT03', dob: "1985-03-19")
    stub_request(:get, "#{T3}/prisoners/#{nomis_id}").
      to_return(body: [{ offenderNo: nomis_id,
                                      gender: 'Male',
                                      convictedStatus: 'Convicted',
                                      latestBookingId: booking_number,
                                      imprisonmentStatus: imprisonment_status,
                                      dateOfBirth: dob }].to_json)

    stub_request(:post, "#{T3}/offender-sentences/bookings").
      with(
        body: [booking_number].to_json
      ).
      to_return(body: [{ offenderNo: nomis_id, bookingId: booking_number,
                                      sentenceDetail: { sentenceStartDate: Time.zone.today - 2.months,
                                                        conditionalReleaseDate: Time.zone.today + 22.months } }].to_json)

    stub_request(:post, "#{T3}/offender-assessments/CATEGORY").
      with(
        body: [nomis_id].to_json
      ).
      to_return(body: {}.to_json)

    stub_request(:get, "#{T3}/bookings/#{booking_number}/mainOffence").
      to_return(body: {}.to_json)
  end

  def stub_movements(movements = [])
    stub_request(:post, "#{T3}/movements/offenders?movementTypes=ADM&movementTypes=TRN&latestOnly=false").
      to_return(body: movements.to_json)
  end

  def stub_poms(prison, poms)
    stub_request(:get, "#{T3}/staff/roles/#{prison}/role/POM").
      with(
        headers: {
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        }).
      to_return(body: poms.to_json)
    poms.each do |pom|
      stub_pom_emails(pom.staffId, pom.emails)
    end
  end

  def stub_pom_emails(staff_id, emails)
    stub_request(:get, "#{T3}/staff/#{staff_id}/emails").
      to_return(body: emails.to_json)
  end

  def stub_signed_in_pom(staff_id, username)
    stub_auth_token
    stub_request(:get, "#{T3}/users/#{username}").
      to_return(body: { 'staffId': staff_id }.to_json)
  end

  def stub_offenders_for_prison(prison, offenders, bookings)
    # Stub the call to get_offenders_for_prison. Takes a list of offender hashes (in nomis camelCase format) and
    # a list of bookings (same key format). It it your responsibility to make sure they contain the data you want
    # and if you provide a booking, that the id matches between the offender and booking hashes.
    elite2listapi = "#{T3}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true"
    elite2bookingsapi = "#{T3}/offender-sentences/bookings"

    # Stub the call that will get the total number of records
    stub_request(:get, elite2listapi).to_return(
      body: {}.to_json,
      headers: { 'Total-Records' => offenders.count.to_s }
    )

    # Return the actual offenders from the call to /locations/description/PRISON/inmates
    stub_request(:get, elite2listapi).with(
      headers: {
        'Page-Limit' => '200',
        'Page-Offset' => '0'
      }).to_return(body: offenders.to_json)

    # Get the booking ids provided
    booking_ids = offenders.map { |h| h.fetch(:bookingId) }
    stub_request(:post, elite2bookingsapi).with(body: booking_ids.to_json).
      to_return(body: bookings.to_json)
  end

  def stub_multiple_offenders(offenders, bookings)
    elite2listapi = "#{T3}/prisoners"
    elite2bookingsapi = "#{T3}/offender-sentences/bookings"

    stub_request(:post, elite2listapi).to_return(
      body: offenders.to_json
    )

    stub_request(:post, elite2bookingsapi).
      to_return(body: bookings.to_json, headers: {})
  end

  def reload_page
    visit current_path
  end
end
