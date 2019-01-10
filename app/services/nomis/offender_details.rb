module Nomis
  class OffenderDetails
    include MemoryModel

    attribute :noms_id, :string
    attribute :offender_id, :string
    attribute :ethnicity, :string
    attribute :first_name, :string
    attribute :surname, :string
    attribute :date_of_birth, :date
    attribute :bookings, :string
    attribute :middle_names, :string
    attribute :gender, :string
    attribute :aliases, :string
    attribute :identifiers, :string

    def release_date
      release_date = release_details.release_date
      release_date&.to_date&.strftime('%m/%d/%Y')
    end

    def nationality
      parsed_ethnicity = JSON.parse ethnicity.gsub('=>', ':')
      @nationality ||= parsed_ethnicity['description']
    end

    def active_booking
      bookings_list = JSON.parse bookings.gsub('=>', ':')
      @active_booking ||= bookings_list.select{ |b| b['activeFlag'] == true }.first
    end

  private

    def release_details
      booking_id = active_booking['bookingId']
      @release_details ||= Nomis::Custody::Api.
                   get_release_details(offender_id, booking_id).data
    end
  end
end
