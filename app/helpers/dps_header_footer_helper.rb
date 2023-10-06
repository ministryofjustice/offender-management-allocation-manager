module DpsHeaderFooterHelper
  def dps_footer_html
    ENABLE_DPS_HEADER_FOOTER ? dps_footer_all.fetch('html').html_safe : ''
  end

  def dps_footer_css
    ENABLE_DPS_HEADER_FOOTER ? dps_footer_all.fetch('css').map { |link| stylesheet_link_tag link }.join("\n").html_safe : ''
  end

  def dps_footer_all
    @dps_footer_all ||= HmppsApi::DpsFrontendComponentsApi.footer
  end
end
