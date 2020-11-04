# frozen_string_literal: true

require 'rake'

namespace :move do
  desc 'Move COM Name field from Allocation to CaseInformation'
  task com_name: :environment do
    Allocation.find_in_batches do |batch|
      allocs = batch.index_by(&:nomis_offender_id)
      CaseInformation.where(nomis_offender_id: allocs.keys).each do |info|
        info.update(com_name: allocs[info.nomis_offender_id]&.com_name)
      end
    end
  end
end
