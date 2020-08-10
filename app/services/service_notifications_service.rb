#frozen_string_literal: true

class ServiceNotificationsService
  def self.notifications(user_roles)
    return [] if user_roles.empty?

    notification_list = ServiceNotifications::Yaml::Data['notifications']
    return [] unless notification_list.is_a?(Array)

    role_notifications = alerts_by_role(notification_list, user_roles)
    alerts_for_today(role_notifications)
  end

private

  def self.alerts_by_role(notifications, user_roles)
    alerts = []

    notifications.each do |alert|
      alerts << alert if user_roles.any? { |role| alert['role'].include?(role) }
    end

    alerts
  end

  def self.alerts_for_today(notifications)
    alerts = []

    notifications.each do |alert|
      today = Time.zone.now.to_date
      start_date = alert['start_date'].to_date
      end_date = start_date + alert['duration'].days
      alerts << alert if today >= start_date && today <= end_date
    end

    alerts
  end
end
