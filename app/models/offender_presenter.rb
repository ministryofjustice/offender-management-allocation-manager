# frozen_string_literal: true

class OffenderPresenter
  delegate :offender_no, :first_name, :last_name, :latest_booking_id,
           :indeterminate_sentence?, :sentence_type_code, :describe_sentence,
           :full_name_ordered, :full_name, :main_offence,
           :home_detention_curfew_eligibility_date, :tariff_date,
           :date_of_birth, :release_date, :parole_eligibility_date,
           :pom_responsibility, :welsh_offender, :case_allocation, :earliest_release_date,
           :category_code, :conditional_release_date, :automatic_release_date,
           :awaiting_allocation_for, :allocated_pom_name, :allocation_date,
           :tier, :crn, :convicted_status, :convicted?,
           :over_18?, :recalled?, :sentenced?, to: :@offender

  def initialize(offender, responsibility)
    @offender = offender
    @responsibility = responsibility
  end

  def case_owner
    if @responsibility
      @responsibility.value
    else
      pom_responsibility = ResponsibilityService.calculate_pom_responsibility(@offender)
      if pom_responsibility == ResponsibilityService::RESPONSIBLE
        'Prison'
      else
        'Probation'
      end
    end
  end
end
