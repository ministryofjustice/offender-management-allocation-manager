# frozen_string_literal: true

namespace :ldu_team do
  desc 'Loads email address into the local_division_unit table'
  task :import, [:filename] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    if args[:filename].blank?
      Rails.logger.error('No file specified')
    else
      YAML.load(File.read(args[:filename])).each do |record|
        Rails.logger.info "Processing record #{record.fetch('ldu_code')} #{record.fetch('team_code')}"
        Team.transaction do
          ldu = LocalDivisionalUnit.find_by(code: record.fetch('ldu_code'))
          if ldu.present?
            ldu.update!(email_address: record.fetch('email_address'), name: record.fetch('ldu_name'))
          else
            ldu = LocalDivisionalUnit.create!(code: record.fetch('ldu_code'),
                                              email_address: record.fetch('email_address'),
                                              name: record.fetch('ldu_name'))
          end
          team = Team.find_by(code: record.fetch('team_code'))
          if team.present?
            team.update!(shadow_code: record.fetch('shadow_team_code'),
                         local_divisional_unit: ldu,
                         name: record.fetch('team_name'))
          else
            Team.create!(shadow_code: record.fetch('shadow_team_code'),
                         code: record.fetch('team_code'),
                         local_divisional_unit: ldu,
                         name: record.fetch('team_name'))
          end
        end
      end
    end
  end
end
