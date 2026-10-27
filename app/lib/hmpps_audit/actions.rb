# frozen_string_literal: true

# Controller actions declared in config/hmpps_audit.yml, either audited or exempt from auditing
module HmppsAudit::Actions
  CONFIG_FILE = Rails.root.join('config/hmpps_audit.yml')

  def self.all
    @all ||= parse(YAML.load_file(CONFIG_FILE))
  end

  # The audit for a controller action, or nil if the action is exempt or undeclared
  def self.find(controller_path, action)
    declaration = all["#{controller_path}##{action}"]
    declaration unless declaration&.key?(:exempt)
  end

  def self.parse(config)
    config.to_h { |key, declaration| [key, parse_declaration(key, declaration).freeze] }.freeze
  end

  def self.parse_declaration(key, declaration)
    if declaration.key?('exempt')
      raise ArgumentError, "Missing exemption reason for #{key}" if declaration['exempt'].blank?
      raise ArgumentError, "Exempt #{key} must not declare an audit" unless declaration.keys == %w[exempt]

      return { exempt: declaration['exempt'] }
    end

    what, subject_type = declaration.values_at('what', 'subject_type')
    raise ArgumentError, "Missing audit `what` for #{key}" if what.blank?
    unless HmppsAudit::Message::SUBJECT_TYPES.include?(subject_type)
      raise ArgumentError, "Unsupported audit subject type `#{subject_type}` for #{key}"
    end

    { what:, subject_type:, subject_id: declaration['subject_id'], query_params: Array(declaration['query_params']) }
  end
  private_class_method :parse_declaration
end
