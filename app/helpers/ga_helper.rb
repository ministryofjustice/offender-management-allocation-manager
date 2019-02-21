module GaHelper
  def ga_enabled?
    Rails.configuration.ga_tracking_id.present?
  end

  def ga_tracking_id
    Rails.configuration.ga_tracking_id.strip
  end
end
