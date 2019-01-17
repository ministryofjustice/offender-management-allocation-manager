module Nomis
  class OffenderActiveBooking
    include MemoryModel

    attribute :noms_id, :string
    attribute :offender_id, :string
    attribute :first_name, :string
    attribute :surname, :string
    attribute :date_of_birth, :date
    attribute :active_booking, :string
    attribute :middle_names, :string

    def release_date
      release_date = release_details.release_date
      release_date&.to_date&.strftime('%m/%d/%Y')
    end

    def full_name
      "#{surname}, #{first_name}".titleize
    end

  private

    def release_details
      active_booking_record = JSON.parse active_booking.gsub('=>', ':')
      booking_id = active_booking_record['bookingId']
      @release_details ||= Nomis::Custody::Api.
                   get_release_details(offender_id, booking_id).data
    end
  end
end
