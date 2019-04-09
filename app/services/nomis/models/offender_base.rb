module Nomis
  module Models
    class OffenderBase
      def sentenced?
        # A prisoner will have had a sentence calculation and for our purposes
        # this means that they will either have a:
        # 1) Release date, or
        # 2) Parole eligibility date, or
        # 3) HDC release date (homeDetentionCurfewEligibilityDate field).
        # If they do not have any of these we should be checking for a tariff date
        # Once we have all the dates we then need to display whichever is the
        # earliest one.
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
    end
  end
end
