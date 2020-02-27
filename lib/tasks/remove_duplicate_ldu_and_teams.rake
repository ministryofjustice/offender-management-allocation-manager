# frozen_string_literal: true

require 'rake'

namespace :cleanup_ldu_data do
  desc 'Clean up the LDU and Team data'
  task populate_team_code: :environment do
    cases = CaseInformation.all
    cases.each do |c|
      c.update!(team_code: Team.where(id: c.team_id).first.code)
    end
  end

  task delete_old_data: :environment do
    Team.destroy_all
    LocalDivisionalUnit.destroy_all
  end

  task map_new_team_ids: :environment do
    cases = CaseInformation.all
    cases.each do |c|
      c.update!(new_team_id: Team.where(code: c.team_code).first.id)
    end
  end
end
