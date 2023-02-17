namespace :deployment do
  desc 'Generate cron job YAML files'
  task :generate_jobs do # rubocop:disable Rails/RakeEnvironment
    header = File.read('deploy/templates/do_not_edit_header.txt')
    template = File.read('deploy/templates/cron_job_template.yaml.erb')
    [
      [
        'production',
        'handover-reminder-upcoming-handover-window-job',
        '5 0 * * *',
        'bundle exec rake handover:send_all_upcoming_handover_window',
      ],
      [
        'production',
        'handover-reminder-handover-date-job',
        '5 1 * * *',
        'bundle exec rake handover:send_all_handover_date',
      ],
      [
        'production',
        'handover-reminder-com-allocation-overdue-job',
        '5 2 * * *',
        'bundle exec rake handover:send_all_com_allocation_overdue',
      ],
      [
        'production',
        'community-api-import',
        '00 06 * * *',
        'bundle exec rake community_api:import',
      ],
      [
        'production',
        'deactivate-cnls',
        '0 4 * * *',
        'bundle exec rake deactivate_cnls:process',
      ],
      [
        'production',
        'early-allocation-events',
        '00 02 * * *',
        'bundle exec rake trigger:early_allocation_events',
      ],
      [
        'production',
        'early-allocation-suitability-email-job',
        '30 4 * * *',
        'bundle exec rake early_allocation_suitability_email:process',
      ],
      [
        'production',
        'handover-chase-email',
        '0 5 * * *',
        'bundle exec rake handover_chase_emails:process',
      ],
    ].each do |env, name, schedule, command|
      warn "Generating #{env}/#{name}, schedule='#{schedule}', command: #{command}"
      target = "deploy/#{env}/cron-#{name}.yaml"
      File.open(target, 'w') do |file|
        file.write header
        file.write "\n"
        file.write eval(Erubi::Engine.new(template).src, binding) # rubocop:disable Security/Eval
      end
    end
  end
end
