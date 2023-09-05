#!/usr/bin/env ruby

raise 'Run it with "bin/rails runner", not on its own' unless Object.constants.include?(:Rails)

if ENV['KUBERNETES_SERVICE_HOST'].present? || ENV['DATABASE_URL'].present? || ! Rails.env.development?
  raise 'Anomaly detected in your environment - you might not be on your local machine or your database' \
        'might not be configured to your local database. Terminating due to risk.'
end

nomis_offender_id = ARGV[0]&.strip
unless /\w+/.match(nomis_offender_id)
  raise "Bad offender '#{nomis_offender_id}' (first arg must be valid NOMIS offender ID)"
end

OffenderService.get_offender(nomis_offender_id)
offender = Offender.find(nomis_offender_id)

dev_data_json = `kubectl -n offender-management-staging exec -qi service/allocation-manager -- bin/rails r '
  Rails.logger.level = Logger::ERROR;
  ci = CaseInformation.find_by(nomis_offender_id: "#{nomis_offender_id}").attributes;
  chd = CalculatedHandoverDate.find_by(nomis_offender_id: "#{nomis_offender_id}").attributes;
  puts({"case_information" => ci, "calc_handover_date" => chd}.to_json)
' 2>/dev/null`

raise 'case_information already exists' if offender.case_information
raise 'calculated_handover_date already exists' if offender.calculated_handover_date

dev_data = ActiveSupport::JSON.decode(dev_data_json)
ci = dev_data.fetch('case_information')
chd = dev_data.fetch('calc_handover_date')
[ci, chd].each do |m|
  m.delete 'id'
  m.delete 'created_at'
  m.delete 'updated_at'
end

CaseInformation.new(ci).save!
CalculatedHandoverDate.new(chd).save!

$stderr.puts 'Offender copied from dev; now allocate to yourself using the web interface'
