# frozen_string_literal: true

Rails.application.config.x.sar_report_version = ENV.fetch('SAR_REPORT_VERSION', 'v1-r1').freeze

Rails.application.config.after_initialize do
  SubjectAccessRequestReport.validate_configuration!
  Rails.logger.info("event=sar_report_configured,version=#{SubjectAccessRequestReport.version}")
end
