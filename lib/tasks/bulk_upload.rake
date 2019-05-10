# frozen_string_literal: true

require 'csv'

namespace :bulk_upload do
  desc 'Import case information for lots of offenders'
  task :import, [:prison, :file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    # Make sure both arguments are specified and bail if not
    Rails.logger.error('No prison specified') if args[:prison].blank?
    Rails.logger.error('No file specified') if args[:file].blank?
    next unless args[:file].present? && args[:prison].present?

    process = proc { |row, row_pos|
      process_row(args[:prison], row, row_pos)
    }

    begin
      CSV.foreach(args[:file], headers: true).with_index(1, &process)
    rescue Errno::ENOENT
      Rails.logger.error("Unable to open file #{args[:file]}")
    end
  end
end

# rubocop:disable Metrics/MethodLength
def process_row(prison, row, row_position)
  id = row['ID']&.strip
  tier = row['Tier']&.strip
  provider = row['Provider']&.strip
  omic = row['OMIC']&.strip

  return if abort_on_blank(id, 'ID', row_position)
  return if abort_on_blank(tier, 'Tier', row_position)
  return if abort_on_blank(provider, 'Provider', row_position)
  return if abort_on_blank(omic, 'OMIC', row_position)
  return if existing_case_info?(id)

  CaseInformation.new.tap { |c|
    c.prison = prison
    c.nomis_offender_id = id
    c.tier = tier
    c.case_allocation = provider
    c.omicable = omic.casecmp('Y').zero?
    c.save!
  }
end
# rubocop:enable Metrics/MethodLength

def existing_case_info?(offender_id)
  if CaseInformation.where(nomis_offender_id: offender_id).count.positive?
    Rails.logger.info("Not overwriting record: #{offender_id}")
    return true
  end

  false
end

def abort_on_blank(field, name, row_position)
  if field.blank?
    Rails.logger.info("#{name} is missing in row #{row_position} .. skipping row")
  end
end
