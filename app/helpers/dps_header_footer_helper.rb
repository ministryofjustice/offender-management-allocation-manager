module DpsHeaderFooterHelper
  def dps_header_html
    dps_header_footer_enabled? ? dps_header_all.fetch('html').html_safe : ''
  end

  def dps_header_css
    dps_header_footer_enabled? ? dps_header_all.fetch('css').map { |link| stylesheet_link_tag link }.join("\n").html_safe : ''
  end

  def dps_header_all
    @dps_header_all ||= HmppsApi::DpsFrontendComponentsApi.header
  end

  def dps_footer_html
    dps_header_footer_enabled? ? dps_footer_all.fetch('html').html_safe : ''
  end

  def dps_footer_css
    dps_header_footer_enabled? ? dps_footer_all.fetch('css').map { |link| stylesheet_link_tag link }.join("\n").html_safe : ''
  end

  def dps_footer_all
    @dps_footer_all ||= HmppsApi::DpsFrontendComponentsApi.footer
  end

  def dps_header_footer_enabled?
    ENABLE_DPS_HEADER_FOOTER || params[:dps_header_footer].present?
  end
end
