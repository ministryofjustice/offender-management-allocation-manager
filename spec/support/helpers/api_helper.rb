module ApiHelper
  def stub_offender(nomis_id)
    booking_number = 754_165

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/prisoners/#{nomis_id}").
      to_return(status: 200, body: [{ offenderNo: nomis_id, gender: 'Male', latestBookingId: booking_number }].to_json)

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
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/#{pom[:staffId]}/emails").
        to_return(status: 200, body: pom[:emails].to_json)
    end
  end
end
