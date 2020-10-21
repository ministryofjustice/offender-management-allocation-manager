# frozen_string_literal: true

module HmppsApi
  module CaseInformationHolder
    attr_reader :welsh_offender, :tier, :mappa_level, :case_allocation, :crn, :ldu, :team, :parole_review_date

    def load_case_information(record)
      return if record.blank?

      @tier = record.tier
      @case_allocation = record.case_allocation
      @welsh_offender = record.welsh_offender == 'Yes'
      @crn = record.crn
      @mappa_level = record.mappa_level
      @ldu = record.local_divisional_unit
      @team = record.team.try(:name)
      @parole_review_date = record.parole_review_date
      @early_allocation = record.latest_early_allocation.present? &&
        (record.latest_early_allocation.eligible? || record.latest_early_allocation.community_decision?)
      @responsibility = record.responsibility
    end

    def early_allocation?
      @early_allocation
    end

    # Having a 'tier' is an alias for having a case information record
    def has_case_information?
      @tier.present?
    end

    def nps_case?
      @case_allocation == 'NPS'
    end

    def responsibility_override?
      @responsibility.present?
    end

    def pom_responsibility
      if @responsibility.nil?
        ResponsibilityService.calculate_pom_responsibility(self)
      elsif @responsibility.value == Responsibility::PRISON
        ResponsibilityService::RESPONSIBLE
      else
        ResponsibilityService::SUPPORTING
      end
    end
  end
end
