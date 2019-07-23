module Nomis
  module Models
    class OffenderBase
      include MemoryModel

      attribute :first_name, :string
      attribute :last_name, :string
      attribute :date_of_birth, :date
      attribute :offender_no, :string
      attribute :convicted_status, :string
      attribute :imprisonment_status, :string

      # Custom attributes
      attribute :crn, :string
      attribute :category_code, :string
      attribute :allocated_pom_name, :string
      attribute :case_allocation, :string
      attribute :omicable, :boolean
      attribute :tier, :string
      attribute :sentence
      attribute :mappa_level, :integer
      attribute :ldu, :string
      attribute :team, :string

      def sentenced?
        # A prisoner will have had a sentence calculation and for our purposes
        # this means that they will either have a:
        # 1) Release date, or
        # 2) Parole eligibility date, or
        # 3) HDC release date (homeDetentionCurfewEligibilityDate field).
        # If they do not have any of these we should be checking for a tariff date
        # Once we have all the dates we then need to display whichever is the
        # earliest one.
        return false if sentence.sentence_start_date.blank?

        sentence.release_date.present? ||
        sentence.parole_eligibility_date.present? ||
        sentence.home_detention_curfew_eligibility_date.present? ||
        sentence.tariff_date.present? ||
        SentenceTypeService.indeterminate_sentence?(imprisonment_status)
      end

      def awaiting_allocation_for
        omic_start_date = Date.new(2019, 2, 4)

        if sentence.sentence_start_date.nil? ||
            sentence.sentence_start_date < omic_start_date
          (Time.zone.today - omic_start_date).to_i
        else
          (Time.zone.today - sentence.sentence_start_date).to_i
        end
      end

      def case_owner
        pom_responsibility = ResponsibilityService.new.calculate_pom_responsibility(self)
        return 'Prison' if pom_responsibility == ResponsibilityService::RESPONSIBLE

        'Probation'
      end

      def earliest_release_date
        sentence.earliest_release_date
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end

      def full_name_ordered
        "#{first_name} #{last_name}".titleize
      end

      # rubocop:disable Rails/Date
      def age
        @age ||= ((Time.zone.now - date_of_birth.to_time) / 1.year.seconds).floor
      end
      # rubocop:enable Rails/Date
    end
  end
end
