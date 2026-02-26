module RoshHelper
  def widget_class(api_resp)
    return '' if api_resp[:status] == :unable
    return 'unknown' if api_resp[:status] == :missing

    api_resp[:overall].tr(' ', '-').downcase
  end

  def level_class(api_val)
    return nil if api_val.blank?

    api_val.tr(' ', '-').downcase
  end

  def risk_display_text(api_val)
    return 'N/A' if api_val.blank?

    api_val.sub(/\A\w/, &:upcase)
  end
end
