# frozen_string_literal: true

require 'rake'

namespace :backfill do
  desc 'Back-fill offender ids for VLO records'
  task vlo: :environment do
    VictimLiaisonOfficer.includes(case_information: :offender).where(nomis_offender_id: nil).find_each do |vlo|
      vlo.update!(offender: vlo.case_information.offender) if vlo.case_information.offender.present?
    end
  end
end
