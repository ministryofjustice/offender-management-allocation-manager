# frozen_string_literal: true

class AutomaticHandoverEmailJob < ApplicationJob
  queue_as :default
  HEADERS = ['Prisoner', 'CRN', 'Prisoner number', 'Handover start date', 'Responsibility handover', 'Release/Parole Date', 'Prison', 'Current POM', 'POM email', 'COM'].freeze
  # Turns out that between? is inclusive at both ends, so a 45-day gap needs a 44-day threshold
  SEND_THRESHOLD = 44.days.freeze

  def perform ldu
    today = Time.zone.today
    ldu_offenders = get_ldu_offenders(ldu)

    # don't send any emails to empty LDUs with no offenders
    if ldu_offenders.any?
      active_prison_codes = Prison.active.map(&:code)

      offenders = ldu_offenders.select { |o|
        active_prison_codes.include?(o.prison_id) &&
            o.sentenced? &&
            o.handover_start_date.present? && o.handover_start_date.between?(today, today + SEND_THRESHOLD)
      }
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
                    allocation&.active? ? HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(allocation.primary_pom_nomis_id).first : nil,
                    offender.allocated_com_name
                ]
          end
        end
        # deliver_now - this is all we are doing, so we want the whole job to repeat if it fails
        CommunityMailer.pipeline_to_community(ldu_name: ldu.name, ldu_email: ldu.email_address, csv_data: csv_data).deliver_now
      else
        CommunityMailer.pipeline_to_community_no_handovers(ldu_name: ldu.name, ldu_email: ldu.email_address).deliver_now
      end
    end
  end

private

  def get_ldu_offenders(ldu)
    offender_ids = if ldu.is_a?(LocalDeliveryUnit)
                     # This is a new LDU record
                     ldu.case_information.map(&:nomis_offender_id)
                   else
                     # This is an old LDU record
                     # TODO: remove old LDUs after LDU/PDU switchover has happened (Feb 2021)
                     ldu.teams.map { |team| team.case_information.map(&:nomis_offender_id) }.flatten
                   end

    offender_ids.map { |offender_id| OffenderService.get_offender(offender_id) }.compact
  end
end
