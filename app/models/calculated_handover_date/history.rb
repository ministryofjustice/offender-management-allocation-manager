class CalculatedHandoverDate::History
  include Enumerable

  def initialize(calculated_handover_date)
    @calculated_handover_date = calculated_handover_date
  end

  def each
    return to_enum(:each) unless block_given?

    @calculated_handover_date
      .versions
      .sort_by(&:created_at)
      .reverse
      .each { |version| yield Item.new(version) }
  end

private

  class Item
    def initialize(version)
      @version         = version
      @base_attributes = from_yaml(version.object)
      @changes         = from_yaml(version.object_changes)
    end

    def updated_at
      @version.created_at
    end

    def responsibility
      from_handover('responsibility')
    end

    def reason
      from_handover('reason')
    end

    def handover_date
      from_handover('handover_date')
    end

    def mappa_level
      offender_attributes['mappa_level']
    end

    def recalled?
      offender_attributes['recalled?']
    end

    def indeterminate_sentence?
      offender_attributes['indeterminate_sentence?']
    end

    def earliest_release_date
      formatted = ->(date) { Date.parse(date).strftime('%d/%m/%Y') }

      if (erd = offender_attributes['earliest_release_for_handover'])
        sprintf('(%{type}) %{date}', type: erd['name'], date: formatted[erd['date']])
      elsif (erd = offender_attributes['earliest_release'])
        sprintf('(%{type}) %{date}', type: erd['type'], date: formatted[erd['date']])
      elsif (erd = offender_attributes['earliest_release_date'])
        formatted[erd]
      end
    end

    def offender_attributes
      @version.offender_attributes_to_archive || {}
    end

  private

    def from_handover(key)
      [@changes, @base_attributes].reduce(nil) { |value, attempt| value || attempt[key] }
    end

    def from_yaml(yaml)
      YAML
        .load(yaml || '{}', permitted_classes: [Date, Time], aliases: true)
        .transform_values { |values| Array(values).last }
    end
  end
end
