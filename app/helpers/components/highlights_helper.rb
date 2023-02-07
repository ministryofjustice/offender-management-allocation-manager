module Components
  module HighlightsHelper
    def highlight_tag(type, level, text_content = nil, more_classes: [], &block_content)
      raise ArgumentError, 'Invalid type' unless %w[primary secondary].include?(type)
      raise ArgumentError, 'Invalid level' unless %w[notice alert].include?(level)

      classes_list = ["highlight-#{type}", "highlight-#{level}"] + more_classes
      if text_content.present?
        tag.div(text_content, class: classes_list)
      elsif block_content.present?
        tag.div(class: classes_list, &block_content)
      end
    end

    def highlight_conditionally(level, secondary_message, condition, &primary_content)
      if condition.call
        capture do
          concat highlight_tag('primary', level, &primary_content)
          concat highlight_tag('secondary', level, secondary_message)
        end
      else
        capture(&primary_content)
      end
    end
  end
end
