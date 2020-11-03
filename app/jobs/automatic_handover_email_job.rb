# frozen_string_literal: true

class AutomaticHandoverEmailJob < ApplicationJob
  queue_as :default
  HEADERS = ['Prisoner', 'CRN', 'Prisoner number', 'Handover start date', 'Responsibility handover', 'Release/Parole Date', 'Prison', 'Current POM', 'POM email'].freeze
  SEND_THRESHOLD = 45.days.freeze

  def perform ldu
    today = Time.zone.today
    offenders = ldu.teams.map { |team| team.case_information.map(&:nomis_offender_id) }.flatten
                    .map { |offender_id| OffenderService.get_offender(offender_id) }
                    .compact
                    .select { |o| o.sentenced? && o.handover_start_date.present? && o.handover_start_date.between?(today, today + SEND_THRESHOLD) }
                    .sort_by(&:handover_start_date)
    if offenders.any?
      allocations = Allocation.where(nomis_offender_id: offenders.map(&:offender_no)).index_by(&:nomis_offender_id)
      csv_data = CSV.generate do |csv|
        csv << HEADERS
        offenders.each do |offender|
          allocation = allocations[offender.offender_no]
          csv <<
            [
                offender.full_name,
                offender.crn,
                offender.offender_no,
                offender.handover_start_date,
                offender.responsibility_handover_date,
                [offender.conditional_release_date, offender.parole_eligibility_date, offender.tariff_date].compact.min,
                PrisonService.name_for(offender.prison_id),
                allocation&.primary_pom_name,
                allocation&.active? ? PrisonOffenderManagerService.get_pom_emails(allocation.primary_pom_nomis_id).first : nil
            ]
        end
      end
      # deliver_now - this is all we are doing, so we want the whole job to repeat if it fails
      CommunityMailer.pipeline_to_community(ldu: ldu, csv_data: csv_data).deliver_now
    else
      CommunityMailer.pipeline_to_community_no_handovers(ldu).deliver_now
    end
  end
end
