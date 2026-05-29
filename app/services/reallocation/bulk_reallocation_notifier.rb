# frozen_string_literal: true

module Reallocation
  class BulkReallocationNotifier
    attr_reader :prison, :source_pom, :target_pom, :email_service, :mailer

    def initialize(prison:, source_pom:, target_pom:, email_service: EmailService, mailer: PomMailer)
      @prison = prison
      @source_pom = source_pom
      @target_pom = target_pom
      @email_service = email_service
      @mailer = mailer
    end

    def call(result)
      return if result.reallocated_cases.empty?

      deliver_individual_emails(result)
      deliver_allocations_created_email(result)
      deliver_allocations_removed_email(result)
    end

  private

    def deliver_individual_emails(result)
      result.reallocated_cases.each do |reallocated_case|
        email_service.send_email(
          allocation: reallocated_case.allocation,
          message: result.message,
          pom_nomis_id: reallocated_case.allocation.primary_pom_nomis_id,
          further_info: reallocated_case.further_info,
          notify_previous_pom: false,
        )
      end
    end

    def deliver_allocations_created_email(result)
      return if target_pom.email_address.blank?

      mailer.with(
        pom_name: target_pom.full_name_ordered,
        pom_email: target_pom.email_address,
        old_pom_name: source_pom.full_name_ordered,
        message: result.message,
        allocations: result.allocations_for_email,
        url: caseload_url_for(target_pom),
      ).bulk_allocations_created.deliver_later
    end

    def deliver_allocations_removed_email(result)
      return if source_pom.email_address.blank?

      mailer.with(
        pom_name: source_pom.full_name_ordered,
        pom_email: source_pom.email_address,
        new_pom_name: target_pom.full_name_ordered,
        message: result.message,
        allocations: result.allocations_for_email,
        url: caseload_url_for(source_pom),
      ).bulk_allocations_removed.deliver_later
    end

    def caseload_url_for(pom)
      Rails.application.routes.url_helpers.prison_staff_caseload_url(prison.code, pom.staff_id)
    end
  end
end
