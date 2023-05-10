module RoshHelper
  def widget_class(api_resp)
    return 'unknown' if api_resp[:status] == :unable
    return 'no' if api_resp[:status] == :missing

    api_resp[:overall].tr(' ', '-').downcase
  end

  def level_class(api_val)
    return 'unknown' if api_val.blank?

    api_val.tr(' ', '-').downcase
  end
end
