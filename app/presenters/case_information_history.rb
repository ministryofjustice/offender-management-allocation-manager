# frozen_string_literal: true

class CaseInformationHistory < BaseHistoryPresenter
  TIMELINE_DETAILS = {
    'tier' => 'Tier',
    'rosh_level' => 'ROSH',
    'enhanced_resourcing' => 'Resourcing',
  }.freeze

  Detail = Struct.new(:label, :from_value, :to_value)

  delegate :created_at, :event, to: :@version

  def initialize(version)
    super()
    @version = version
  end

  def self.timeline_entries_for(nomis_offender_id)
    PaperTrail::Version
      .where(item_type: 'CaseInformation', nomis_offender_id:)
      .filter_map do |version|
        history = new(version)
        history if history.event == 'destroy' || history.change_details.any?
      end
  end

  def to_partial_path
    "case_history/case_information/#{event}"
  end

  def created_by_name
    paper_trail_created_by_name(@version)
  end

  def change_details
    return [] if event == 'destroy'

    changeset = @version.changeset || {}

    TIMELINE_DETAILS.filter_map do |attribute, label|
      next if attribute == 'rosh_level' && FeatureFlags.rosh_level.disabled?
      next unless changeset.key?(attribute)

      previous_value, new_value = changeset.fetch(attribute, [nil, nil])

      Detail.new(
        label,
        detail_value_for(attribute, previous_value),
        detail_value_for(attribute, new_value)
      )
    end
  end

private

  def detail_value_for(attribute, value)
    return '(unset)' if value.nil?

    case attribute
    when 'rosh_level'
      value.to_s.humanize
    when 'enhanced_resourcing'
      ActiveModel::Type::Boolean.new.cast(value) ? 'enhanced' : 'standard'
    else
      value
    end
  end
end
