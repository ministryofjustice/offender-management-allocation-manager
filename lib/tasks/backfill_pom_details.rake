# frozen_string_literal: true

require 'rake'

namespace :backfill do
  desc 'Back-fill pom_details with prison_code'
  task pom_details: :environment do
    Rails.logger = Logger.new(STDOUT)

    Prison.all.each do |prison|
      PrisonOffenderManagerService.get_poms_for(prison.code).map(&:staff_id).each { |staff_id|
        pom = PomDetail.find_by! nomis_staff_id: staff_id
        pom.update! prison_code: prison.code if pom.prison_code.nil?
      }
    end

    PomDetail.where(prison_code: nil).each do |pom_detail|
      prims = Allocation.where(primary_pom_nomis_id: pom_detail.nomis_staff_id)
      allocs = Allocation.where(secondary_pom_nomis_id: pom_detail.nomis_staff_id).or(prims)
      if allocs.count == 0
        pom_detail.destroy
      else
        pom_detail.update! prison_code: allocs.last.prison
      end
    end
  end
end
