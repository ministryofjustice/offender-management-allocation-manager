# frozen_string_literal: true

module Debugging
  class HandoverAttributeComparison
    def initialize(item, previous_item)
      @item = item
      @previous_item = previous_item
    end

    def rows
      (current_attributes.keys | previous_attributes.keys).sort.map do |key|
        current_state = attribute_state(current_attributes, key)
        previous_state = attribute_state(previous_attributes, key)

        {
          label: key.humanize,
          before: @previous_item.nil? ? 'No earlier value' : previous_attribute_value(previous_attributes, key),
          after: current_attribute_value(current_attributes, previous_attributes, key),
          changed: attribute_changed?(previous_state, current_state, previous_attributes[key], current_attributes[key])
        }
      end
    end

  private

    def current_attributes
      @item.offender_attributes
    end

    def previous_attributes
      @previous_item&.offender_attributes || {}
    end

    def attribute_state(attributes, key)
      return :missing unless attributes.key?(key)

      attributes[key].nil? ? :unset : :value
    end

    def previous_attribute_value(attributes, key)
      case attribute_state(attributes, key)
      when :missing then 'Not recorded'
      when :unset then '—'
      else attributes[key]
      end
    end

    def current_attribute_value(current_attributes, previous_attributes, key)
      current_state = attribute_state(current_attributes, key)
      previous_state = attribute_state(previous_attributes, key)

      case current_state
      when :missing
        'Not recorded'
      when :unset
        previous_state == :value ? '(unset)' : '—'
      else
        current_attributes[key]
      end
    end

    def attribute_changed?(previous_state, current_state, previous_value, current_value)
      if previous_state == :value && current_state == :value
        previous_value != current_value
      elsif previous_state == :value || current_state == :value
        true
      else
        false
      end
    end
  end
end
