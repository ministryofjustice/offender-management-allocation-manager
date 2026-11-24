# frozen_string_literal: true

class SubjectAccessRequestReport
  DATA_SERVICES = {
    'v1-r1' => SarOffenderDataServiceV1,
    'v1-r2' => SarOffenderDataServiceV1,
  }.freeze

  class ConfigurationError < StandardError; end

  class << self
    def template_path
      Rails.root.join('config/templates', "#{version}_sar_template.mustache")
    end

    def template_content
      File.read(template_path, encoding: 'UTF-8')
    end

    def find(nomis_offender_id, from_date, to_date)
      DATA_SERVICES.fetch(version).new(nomis_offender_id, from_date, to_date).find
    end

    def version
      configured_version = Rails.application.config.x.sar_report_version
      return configured_version if DATA_SERVICES.key?(configured_version)

      raise ConfigurationError, "Unsupported SAR_REPORT_VERSION #{configured_version.inspect}. Supported versions: #{DATA_SERVICES.keys.join(', ')}"
    end

    def validate_configuration!
      return if template_path.file?

      raise ConfigurationError, "Invalid subject access request configuration. File '#{template_path}' not found"
    end
  end
end
