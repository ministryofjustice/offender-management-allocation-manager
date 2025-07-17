# frozen_string_literal: true

class EmailService
  class << self
    def send_email(message:, allocation:, pom_nomis_id:, further_info: {})
      pom = pom_for(allocation, pom_nomis_id)
      return if pom.email_address.blank?

      send_deallocation_email pom: pom, allocation: allocation, further_info: further_info
      deliver_new_allocation_email pom: pom, message: message, allocation: allocation, further_info: further_info
    end

    def send_coworking_primary_email(message:, allocation:)
      pom_nomis_id = allocation.primary_pom_nomis_id
      pom = pom_for(allocation, pom_nomis_id)
      offender = offender_for allocation
      coworking_pom_name = allocation.secondary_pom_name
      if pom.email_address.present?
        PomMailer.with(
          message: message,
          pom_name: pom.first_name.capitalize,
          offender_name: offender.full_name,
          nomis_offender_id: offender.offender_no,
          coworking_pom_name: coworking_pom_name,
          pom_email: pom.email_address,
          url: Rails.application.routes.url_helpers.prison_staff_caseload_url(allocation.prison, pom.staff_id)
        ).allocate_coworking_pom.deliver_later
      end
    end

    def send_secondary_email(pom_firstname:, pom_nomis_id:, message:, allocation:)
      pom = pom_for(allocation, pom_nomis_id)
      offender = offender_for allocation

      if pom.email_address.present?
        PomMailer.with(
          message: message,
          pom_name: pom_firstname.capitalize,
          offender_name: offender.full_name,
          nomis_offender_id: offender.offender_no,
          responsibility: current_responsibility(offender),
          responsible_pom_name: allocation.primary_pom_name,
          pom_email: pom.email_address,
          url: Rails.application.routes.url_helpers.prison_staff_caseload_url(allocation.prison, pom.staff_id)
        ).secondary_allocation_email.deliver_later
      end
    end

    def send_cowork_deallocation_email(allocation:, pom_nomis_id:, secondary_pom_name:)
      pom = pom_for(allocation, pom_nomis_id)
      return if pom.email_address.blank?

      offender = offender_for allocation

      PomMailer.with(
        pom_name: pom.first_name.capitalize,
        email_address: pom.email_address,
        secondary_pom_name: secondary_pom_name,
        nomis_offender_id: offender.offender_no,
        offender_name: offender.full_name,
        url: Rails.application.routes.url_helpers.prison_staff_caseload_url(allocation.prison, pom.staff_id)
      ).deallocate_coworking_pom.deliver_later
    end

  private

    def offender_for(allocation)
      OffenderService.get_offender(allocation.nomis_offender_id)
    end

    def pom_for(allocation, pom_nomis_id)
      Prison.find(allocation.prison).get_single_pom(pom_nomis_id)
    end

    def current_responsibility(offender)
      offender.pom_responsible? ? 'responsible' : 'supporting'
    end

    def previous_pom_for(allocation)
      # Check the versions (there MUST be previous records if this is a reallocation)
      # and find the last version with a primary_pom id that is not the same as the
      # allocation. That will be the POM that is notified of a reallocation.
      versions = allocation.get_old_versions

      previous = versions.reverse.detect do |version|
        version.primary_pom_nomis_id.present? && version.primary_pom_nomis_id != allocation.primary_pom_nomis_id
      end
      return nil if previous.blank?

      HmppsApi::NomisUserRolesApi.staff_details(previous.primary_pom_nomis_id)
    end

    def send_deallocation_email(pom:, allocation:, further_info:)
      if allocation.event == 'reallocate_primary_pom'
        previous_pom = previous_pom_for(allocation)
        # If the previous pom does not have email configured, do not
        # try and email them.
        return if previous_pom.nil? || previous_pom.email_address.blank?

        offender = offender_for(allocation)

        PomMailer.with(
          previous_pom_name: previous_pom.first_name.capitalize,
          responsibility: current_responsibility(offender),
          previous_pom_email: previous_pom.email_address,
          new_pom_name: pom.full_name,
          offender_name: offender.full_name,
          offender_no: offender.offender_no,
          prison: Prison.find(pom.agency_id).name,
          url: Rails.application.routes.url_helpers.prison_staff_caseload_url(allocation.prison, pom.staff_id),
          further_info: further_info
        ).deallocation_email.deliver_later
      end
    end

    def deliver_new_allocation_email(pom:, message:, allocation:, further_info:)
      offender = offender_for(allocation)

      PomMailer.with(
        pom_name: pom.first_name.capitalize,
        responsibility: current_responsibility(offender),
        pom_email: pom.email_address,
        offender_name: offender.full_name,
        offender_no: offender.offender_no,
        message: message,
        url: Rails.application.routes.url_helpers.prison_prisoner_allocation_url(allocation.prison, offender.offender_no),
        further_info: further_info
      ).new_allocation_email.deliver_later
    end
  end
end
