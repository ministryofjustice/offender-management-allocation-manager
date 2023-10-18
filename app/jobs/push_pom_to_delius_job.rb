# frozen_string_literal: true

class PushPomToDeliusJob < ApplicationJob
  queue_as :default

  # Not much point retrying a 404 error
  discard_on Faraday::ResourceNotFound

  def perform(allocation)
    if allocation.primary_pom_nomis_id.nil?
      HmppsApi::CommunityApi.unset_pom(allocation.nomis_offender_id)
      publish_audit_event(allocation.nomis_offender_id, 'removed')

    else

      # The allocation model has formatted pom names ‘firstname, surname’ that PrisonOffenderManagerService
      # splits up to allow them to be pushed separately.
      staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(allocation.primary_pom_nomis_id)

      params = {
        offender_no: allocation.nomis_offender_id,
        prison: allocation.prison,
        forename: staff.first_name,
        surname: staff.last_name
      }

      HmppsApi::CommunityApi.set_pom(**params)
      publish_audit_event(allocation.nomis_offender_id, 'changed', params.except(:offender_no))
    end
  end

private

  def publish_audit_event(offender_no, tag, data = {})
    AuditEvent.publish(
      nomis_offender_id: offender_no,
      tags: %w[job push_pom_to_delius_job allocation] + [tag],
      system_event: true,
      data: data.stringify_keys
    )
  end
end
