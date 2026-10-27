# frozen_string_literal: true

# Controller actions declared in config/hmpps_audit.yml: audited, exempt from auditing, or still to evaluate
module HmppsAudit::Actions
  CONFIG_FILE = Rails.root.join('config/hmpps_audit.yml')

  class UndeclaredActionError < StandardError; end

  def self.all
    @all ||= parse(YAML.load_file(CONFIG_FILE))
  end

  # The audit for a controller action, or nil if the action is exempt or still to evaluate
  def self.find(controller_path, action)
    key = "#{controller_path}##{action}"
    declaration = all.fetch(key) do
      raise UndeclaredActionError, "Declare #{key} in config/hmpps_audit.yml as audited or exempt"
    end
    declaration if declaration.key?(:what)
  end

  def self.parse(config)
    config.to_h { |key, declaration| [key, parse_declaration(key, declaration).freeze] }.freeze
  end

  def self.parse_declaration(key, declaration)
    return { todo: true } if declaration.key?('todo')

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
