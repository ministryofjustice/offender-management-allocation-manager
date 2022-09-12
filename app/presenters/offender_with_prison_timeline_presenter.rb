# frozen_string_literal: true

class OffenderWithPrisonTimelinePresenter
  delegate :offender_no, :full_name, :last_name, :earliest_release_date,
           :earliest_release, :latest_temp_movement_date, :allocated_com_name,
           :case_allocation, :complexity_level, :date_of_birth, :tier,
           :probation_record, :handover_start_date, :restricted_patient?,
           :location, :responsibility_handover_date, :pom_responsible?,
           :com_responsible?, :pom_supporting?, :coworking?,
           :awaiting_allocation_for, to: :@offender

  def initialize(offender, prison_timeline)
    @offender = offender
    @prison_timeline = prison_timeline
  end

  def additional_information
    attended_prisons = prison_timeline['prisonPeriod'].map { |p| p['prisons'] } .flatten

    # Remove only ONE of any prison codes that match the current prison
    previously_attended_prisons = (attended_prisons.reject { |p| p == offender.prison.code }) +
      (attended_prisons.select { |p| p == offender.prison.code } .drop(1))

    [].tap do |response|
      response << 'Recall' if offender.recalled?

      if previously_attended_prisons.empty?
        response << 'New to custody'
      elsif previously_attended_prisons.include?(offender.prison.code)
        response << 'Returning to this prison'
      else
        response << 'New to this prison'
      end
    end
  end

  private

  attr_reader :offender, :prison_timeline
end

