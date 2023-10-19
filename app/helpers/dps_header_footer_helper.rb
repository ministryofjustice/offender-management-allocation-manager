module DpsHeaderFooterHelper
  def dps_components_retrieved_successfully?
    dps_header_footer.fetch('status') == 'ok'
  end

  def dps_component_html(component)
    check_component(component)

    dps_header_footer.fetch(component).fetch('html').html_safe
  end

  def dps_component_css(component)
    check_component(component)

    dps_header_footer.fetch(component).fetch('css').map { |link|
      stylesheet_link_tag link, media: 'all', 'data-turbolinks-track': 'reload'
    }.join("\n").html_safe
  end

  def dps_component_js(component)
    dps_header_footer.fetch(component).fetch('javascript').map { |link|
      javascript_include_tag link, 'data-turbolinks-track': 'reload'
    }.join("\n").html_safe
  end

private

  def check_component(component)
    raise ArgumentError, 'Component must be "header" or "footer"' unless ['header', 'footer'].include?(component)
  end
end
