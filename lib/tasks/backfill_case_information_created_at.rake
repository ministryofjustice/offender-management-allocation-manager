# frozen_string_literal: true

namespace :backfill do
  namespace :case_information_created_at do
    # Allocation dates are estimates, not actual case creation dates. For an
    # earliest allocation in 2020 or later, use the assumed 2019 timestamp cutoff.
    desc 'Preview CaseInformation creation estimates from 14 February to 31 December 2019 UTC'
    task dry_run: :environment do
      puts BackfillCaseInformationCreatedAtService.new(dry_run: true).call.inspect
    end

    desc 'Backfill CaseInformation creation dates with estimates from 14 February to 31 December 2019 UTC'
    task process: :environment do
      puts BackfillCaseInformationCreatedAtService.new(dry_run: false).call.inspect
    end
  end
end
