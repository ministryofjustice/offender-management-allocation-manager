module ServiceNotifications
  class Yaml
    Data = YAML.load(File.read('app/notifications/service_notifications.yaml'))
  end
end
