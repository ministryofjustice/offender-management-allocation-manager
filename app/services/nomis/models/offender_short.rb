module Nomis
  module Models
    class OffenderShort
      include MemoryModel

      attribute :booking_id, :integer
      attribute :booking_no, :string
      attribute :offender_no, :string
      attribute :first_name, :string
      attribute :middle_name, :string
      attribute :last_name, :string
      attribute :date_of_birth, :string
      attribute :age, :integer
      attribute :alerts_codes, :string
      attribute :alerts_details, :string
      attribute :agency_id, :string
      attribute :assigned_living_unit_id, :integer
      attribute :assigned_living_unit_desc, :string
      attribute :facial_image_id, :string
      attribute :assigned_officer_user_id, :string
      attribute :aliases, :string
      attribute :iep_level, :string
      attribute :category_code, :string
      attribute :rnum, :integer
      attribute :tier, :string
      attribute :allocated_pom_name, :string
      attribute :allocation_date, :date
      attribute :case_allocation, :string
      attribute :omicable, :boolean
      attribute :convicted_status, :string
      attribute :sentence_start_date, :date
      attribute :release_date, :date
      attribute :parole_eligibility_date, :date
      attribute :home_detention_curfew_eligibility_date, :date
      attribute :tariff_date, :date

      def sentenced?
        # A prisoner will have had a sentence calculation and for our purposes
        # this means that they will either have a:
        # 1) Release date, or
        # 2) Parole eligibility date, or
        # 3) HDC release date (homeDetentionCurfewEligibilityDate field).
        # If they do not have any of these we should be checking for a tariff date
        # Once we have all the dates we then need to display whichever is the
        # earliest one.
        release_date.present? ||
        parole_eligibility_date.present? ||
        home_detention_curfew_eligibility_date.present? ||
        tariff_date.present?
      end

      def sentence_detail=(sentence_detail)
        self.release_date = sentence_detail.release_date
        self.sentence_start_date = sentence_detail.sentence_start_date
        self.parole_eligibility_date = sentence_detail.parole_eligibility_date
        self.tariff_date = sentence_detail.tariff_date
        self.home_detention_curfew_eligibility_date =
          sentence_detail.home_detention_curfew_eligibility_date
      end

      def earliest_release_date
        dates = [
          release_date,
          parole_eligibility_date,
          home_detention_curfew_eligibility_date,
          tariff_date
        ].compact
        return nil if dates.empty?

        dates.min
      end

      def awaiting_allocation_for
        omic_start_date = Date.new(2019, 2, 4)

        if sentence_start_date.nil? || sentence_start_date < omic_start_date
          (Time.zone.today - omic_start_date).to_i
        else
          (Time.zone.today - sentence_start_date).to_i
        end
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
