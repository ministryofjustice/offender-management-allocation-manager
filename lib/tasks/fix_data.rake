# frozen_string_literal: true

require_relative '../allocation_validation'

namespace :fix_data do
  desc 'Fixes data for incorrect transfer/releases/allocations'
  task :for_prison, [:prison] => [:environment] do |_task, args|
    prisons = args[:prison].split

    prisons.each do |prison|
      puts "Attempting to process #{prison}"
      if Prison.find_by(code: prison).nil?
        puts "Unable to find prison #{prison}"
        next
      end

      AllocationValidation.fixup(prison)
    end
  end
end
