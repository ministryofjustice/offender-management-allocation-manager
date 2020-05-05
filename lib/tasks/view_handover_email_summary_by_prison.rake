# frozen_string_literal: true

require 'rake'

desc 'See how many prisoners in a given prison are missing email address for handover, and why'
task handover_email_summary_by_prison: :environment do
  ARGV.each do |a| task a.to_sym do; end end
  prison_code = ARGV[1]

  offenders = Prison.new(prison_code).offenders

  pp ViewHandoverEmailAddressesSummary.new.execute(offenders)
end
