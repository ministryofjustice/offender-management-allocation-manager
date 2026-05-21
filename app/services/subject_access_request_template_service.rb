# frozen_string_literal: true

class SubjectAccessRequestTemplateService
  TEMPLATE_PATH = Rails.root.join('config/templates/sar_template.mustache').freeze

  class ConfigurationError < StandardError; end

  class << self
    def template_path
      TEMPLATE_PATH
    end

    def content
      File.read(template_path, encoding: 'UTF-8')
    end

    def validate_configuration!
      return if template_path.file?

      raise ConfigurationError, "Invalid subject access request configuration. File '#{template_path}' not found"
    end
  end
end
