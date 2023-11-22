# frozen_string_literal: true

class AutomaticHandoverEmailJob < ApplicationJob
  queue_as :default
  HEADERS = ['Prisoner', 'CRN', 'Prisoner number', 'Handover completion due', 'Release/Parole Date', 'Prison', 'Current POM', 'POM email', 'COM'].freeze
  # Turns out that between? is inclusive at both ends, so a 45-day gap needs a 44-day threshold
  SEND_THRESHOLD = 44.days.freeze

  def perform(ldu)
    ldu_offenders = get_ldu_offenders(ldu)

    # don't send any emails to empty LDUs with no offenders
    if ldu_offenders.any?
      offenders = filter_offenders(ldu_offenders)

      if offenders.any?
        allocations = AllocationHistory.where(nomis_offender_id: offenders.map(&:offender_no)).index_by(&:nomis_offender_id)
        csv_data = CSV.generate do |csv|
          csv << HEADERS
          offenders.each do |offender|
            allocation = allocations[offender.offender_no]
            csv <<
                [
                  offender.full_name,
                  offender.crn,
                  offender.offender_no,
                  offender.handover_date,
                  [offender.conditional_release_date, offender.parole_eligibility_date, offender.tariff_date].compact.min,
                  Prison.find(offender.prison_id).name,
                  allocation&.primary_pom_name,
                  allocation&.active? ? HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(allocation.primary_pom_nomis_id).first : nil,
                  offender.allocated_com_name
                ]
          end
        end
        # deliver_now - this is all we are doing, so we want the whole job to repeat if it fails
        CommunityMailer.with(ldu_name: ldu.name, ldu_email: ldu.email_address, csv_data: csv_data).pipeline_to_community.deliver_now
        logger.info "event=ldu_handover_email_with_csv,ldu_code=#{ldu.code},offender_count=#{offenders.size}|Email sent to LDU with CSV"
      else
        CommunityMailer.with(ldu_name: ldu.name, ldu_email: ldu.email_address).pipeline_to_community_no_handovers.deliver_now
        logger.info "event=ldu_handover_email_no_csv,ldu_code=#{ldu.code}|Email sent to LDU no CSV"
      end
    end
  end

private

  def filter_offenders(offenders, run_on: Time.zone.today, last_report_on: Time.zone.today - 1.month)
    active_prison_codes = Prison.active.map(&:code)

    offenders.select { |o|
      active_prison_codes.include?(o.prison_id) &&
        o.sentenced? &&
        o.handover_start_date.present? && (
          o.handover_start_date.between?(run_on, run_on + SEND_THRESHOLD) || (
            # This catches handovers that got calculated after the last report ran
            # with handovers in the past and would therefore have been missed
            o.handover_start_date < run_on &&
            o.handover_last_calculated_at.present? &&
            o.handover_last_calculated_at > last_report_on
          )
        )
    }.sort_by(&:handover_start_date)
  end

  def get_ldu_offenders(ldu)
    ldu.case_information.map(&:nomis_offender_id).map { |offender_id| OffenderService.get_offender(offender_id) }.compact
  end
end
