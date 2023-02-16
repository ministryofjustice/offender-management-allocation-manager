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
