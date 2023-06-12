module ServiceNotifications
  class Yaml
    Data = YAML.unsafe_load(File.read('app/notifications/service_notifications.yaml'))
  end
end
