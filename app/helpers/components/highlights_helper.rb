module Components
  module HighlightsHelper
    def highlight_tag(type, level, text_content = nil, more_classes: [], &block_content)
      raise 'Invalid type' unless %w[primary secondary].include?(type)
      raise 'Invalid level' unless %w[notice alert].include?(level)

      content = if text_content.present?
                  text_content
                elsif block_content.present?
                  capture(&block_content)
                end

      tag.div(content, class: ["highlight-#{type}", "highlight-#{level}"] + more_classes)
    end

    def highlight_conditionally(level, secondary_message, condition, &primary_content)
      markup = []

      if condition.call
        markup.push highlight_tag('primary', level, &primary_content)
        markup.push highlight_tag('secondary', level, secondary_message)
      else
        markup.push capture(&primary_content)
      end

      markup.join.html_safe
    end
  end
end
