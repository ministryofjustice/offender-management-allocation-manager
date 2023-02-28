module ViewSpecHelper
  def self.included(mod)
    mod.include(ActionView::Helpers::SanitizeHelper)
  end

  def page
    Nokogiri::HTML5.parse(rendered)
  end

  def partial
    Nokogiri::HTML5.fragment(rendered)
  end

  def rendered_text
    strip_tags(rendered).gsub(/\s+/, ' ').strip
  end
end

RSpec.configure do |config|
  config.include(ViewSpecHelper, type: :view)
end
