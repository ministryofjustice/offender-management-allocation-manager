module Nomis
  module Elite2
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
        sentence_detail['sentenceStartDate']
      end

      def release_date
        sentence_detail['releaseDate']
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
