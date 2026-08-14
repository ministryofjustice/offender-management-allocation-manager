# frozen_string_literal: true

desc 'Persist the omic eligibility for each offender in each prison'
task persist_omic_eligibility: :environment do
  PersistOmicEligibilityService.new.call
end
