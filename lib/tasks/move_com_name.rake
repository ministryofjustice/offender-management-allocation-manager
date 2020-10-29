# frozen_string_literal: true

require 'rake'

BATCH_SIZE = 1000

namespace :move do
  desc 'Move COM Name field from Allocation to CaseInformation'
  task com_name: :environment do
    scope = Allocation.where.not(com_name: nil)
    count = 1 + scope.count / BATCH_SIZE
    scope.find_in_batches(batch_size: BATCH_SIZE).each_with_index do |batch, index|
      puts "Allocation batch #{index + 1}/#{count}"
      allocs = batch.index_by(&:nomis_offender_id)
      CaseInformation.where(com_name: nil, nomis_offender_id: allocs.keys).each do |info|
        info.update(com_name: allocs[info.nomis_offender_id]&.com_name)
      end
    end
  end
end
