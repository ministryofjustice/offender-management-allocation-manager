module Uptime
  def self.application_did_boot!
    @application_booted_at = Time.zone.now
  end

  def self.application_booted_at
    @application_booted_at || Time.zone.now
  end

  def self.duration_in_seconds
    Time.zone.now.minus_with_coercion(application_booted_at)
  end
end
