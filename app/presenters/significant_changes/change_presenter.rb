# frozen_string_literal: true

class SignificantChanges
  class ChangePresenter
    delegate :type, to: :@change

    def initialize(change, review:)
      @change = change
      @review = review
    end

    def title = I18n.t("significant_changes.#{type}.title", raise: true)
    def changed_at = @change.changed_at.to_date.to_fs(:rfc822)
    def from_value = format_value(@change.from_value)
    def to_value = format_value(@change.to_value)

    def explanation
      return unless type == :handover

      I18n.t("significant_changes.handover.explanation.#{@review.allocated_pom_position}", raise: true)
    end

  private

    def format_value(value)
      case type
      when :tier then "Tier #{value}"
      when :rosh then value.humanize
      when :handover then value.to_fs(:rfc822)
      else raise ArgumentError, "Unknown change type: #{type}"
      end
    end
  end
end
