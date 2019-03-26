module Nomis
  module Models
    class SentenceDetail
      include MemoryModel

      attribute :first_name, :string
      attribute :last_name, :string
      attribute :booking_id, :integer
      attribute :offender_no
      attribute :agency_location_id
      attribute :sentence_detail
      attribute :date_of_birth
      attribute :agency_location_desc
      attribute :facial_image_id
      attribute :internal_location_desc

      def sentence_date
        sentence_detail['sentence_start_date']
      end

      def release_date
        sentence_detail['release_date']
      end

      def tariff_date
        sentence_detail['tariff_date']
      end

      def parole_eligibility_date
        sentence_detail['parole_eligibility_date']
      end

      def indeterminate_release_date?
        release_date.nil? && tariff_date.present?
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
