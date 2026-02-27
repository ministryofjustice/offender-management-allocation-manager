module RoshHelper
  def widget_class(rosh)
    return '' if rosh.unable?
    return 'unknown' if rosh.missing?

    rosh.overall.tr('_', '-').downcase
  end

  def level_class(api_val)
    return nil if api_val.blank?

    api_val.tr('_', '-').downcase
  end

  def overall_display_text(api_val)
    return 'UNKNOWN LEVEL' if api_val.blank?

    api_val.humanize.upcase
  end

  def risk_display_text(api_val)
    return 'N/A' if api_val.blank?

    api_val.humanize
  end
end
