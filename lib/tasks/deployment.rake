namespace :deployment do
  desc 'Generate cron job YAML files'
  task :generate_jobs do # rubocop:disable Rails/RakeEnvironment
    header = File.read('deploy/templates/do_not_edit_header.txt')
    template = File.read('deploy/templates/cron_job_template.yaml.erb')
    [
      # Staging
      [
        'staging',
        'recalculate-handover-dates',
        '30 6 * * *',
        'bundle exec rake recalculate_handover_dates',
      ],
      [
        'staging',
        'integration-test-cleanup',
        '30 6 * * *',
        'bundle exec rake integration_tests:clean_up',
      ],

      # Preprod
      [
        'preprod',
        'community-api-import',
        '30 6 * * *',
        'bundle exec rake community_api:import',
      ],
      [
        'preprod',
        'early-allocation-events',
        '0 7 * * *',
        'bundle exec rake trigger:early_allocation_events',
      ],
      [
        'preprod',
        'process-movements',
        '30 7 * * *',
        'bundle exec rake movements:process',
      ],

      # Production
      [
        'production',
        'handover-reminders-job',
        '5 0 * * *',
        'bundle exec rake handover:send_all_handover_reminders',
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
      [
        'production',
        'handover-email-job',
        '4 9 1 * *',
        'bundle exec rake cronjob:handover_email',
      ],
      [
        'production',
        'offender-manager-process-movements',
        '0 2 * * *',
        'bundle exec rake movements:process',
      ],
      [
        'production',
        'recalculate-handover-dates',
        '0 3 * * *',
        'bundle exec rake recalculate_handover_dates',
      ],
      [
        'production',
        'repush-all-handover-dates-to-delius-job',
        '0 6 * * 1',
        'bundle exec rake repush_all_handover_dates_to_delius',
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
