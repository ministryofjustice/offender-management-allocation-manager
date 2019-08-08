# frozen_string_literal: true

namespace :delius do
  desc 'decrypt delius export xlsx file'
  task :decrypt, [:input_file, :output_file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    input = args[:input_file]
    output = args[:output_file]

    # Make sure both arguments are specified and bail if not
    Rails.logger.error('No input file provided') if input.blank?
    Rails.logger.error('No output file specified') if output.blank?
    next unless input.present? && output.present?

    std_output = `bin/msoffice-crypt -d #{input} #{output} -p #{password}`
    lines = std_output.split("\n")
    if lines.count > 1
      Rails.logger.error(lines.last)
      abort(lines.last)
    end
  end
end

def password
  @password ||= ENV['DELIUS_XLSX_PASSWORD']
end
