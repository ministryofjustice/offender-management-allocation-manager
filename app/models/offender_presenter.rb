# frozen_string_literal: true

class OffenderPresenter
  delegate :offender_no, :first_name, :last_name, :latest_booking_id,
           :indeterminate_sentence?, :sentence_type_code, :describe_sentence,
           :full_name_ordered, :full_name, :main_offence,
           :sentence_start_date, :team, :prison_id,
           :home_detention_curfew_eligibility_date, :tariff_date,
           :date_of_birth, :release_date, :parole_eligibility_date,
           :welsh_offender, :case_allocation, :earliest_release_date,
           :category_code, :conditional_release_date, :automatic_release_date,
           :awaiting_allocation_for, :allocated_pom_name, :allocation_date,
           :tier, :parole_review_date, :crn, :convicted_status, :convicted?, :ldu,
           :handover_start_date, :responsibility_handover_date,
           :over_18?, :recalled?, :sentenced?, :immigration_case?, to: :@offender

  def initialize(offender, responsibility)
    @offender = offender
    @responsibility = responsibility
  end

  def pom_responsibility
    if @responsibility
      if @responsibility.value == Responsibility::PRISON
        ResponsibilityService::RESPONSIBLE
      else
        ResponsibilityService::SUPPORTING
      end
    else
      @offender.pom_responsibility
    end
  end

  def recommended_pom_type
    rec_type = RecommendationService.recommended_pom_type(@offender)

    if rec_type == RecommendationService::PRISON_POM
      'Prison officer'
    else
      'Probation officer'
    end
  end

  def non_recommended_pom_type
    rec_type = RecommendationService.recommended_pom_type(@offender)

    if rec_type == RecommendationService::PRISON_POM
      'Probation officer'
    else
      'Prison officer'
    end
  end
end
