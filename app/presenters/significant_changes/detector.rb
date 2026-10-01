# frozen_string_literal: true

class SignificantChanges
  # Works out whether one tracked attribute has changed significantly.
  #
  # Subclasses declare what they track with `tracks`, and implement `band` to
  # group values by their effect on the POM recommendation (nil if the value is
  # irrelevant). For example, tiers are banded as "A" or "not A".
  #
  # A change is significant when the band of the first value (at the start date)
  # differs from the band of the latest value, so a change that has since been
  # reverted isn't flagged. Override `significant?` for any extra conditions.
  #
  class Detector
    class << self
      attr_reader :type, :label, :item_type, :attribute

      def tracks(type, label:, item_type:, attribute:)
        @type = type
        @label = label
        @item_type = item_type
        @attribute = attribute
      end
    end

    delegate :type, :label, :item_type, :attribute, to: :class

    def initialize(review, versions)
      @review = review
      @versions = versions
    end

    def change
      return if timeline.empty?

      from_value = timeline.first[:from]
      to_value = timeline.last[:to]
      from_band = band(from_value)
      to_band = band(to_value)
      return if from_band.nil? || to_band.nil? || from_band == to_band

      change = Change.new(type:, label:, from_value:, to_value:, changed_at: changed_at(to_band))
      change if significant?(change) && review.recommendation_differs_from_allocation?
    end

  private

    attr_reader :review

    def band(_value) = raise NotImplementedError
    def significant?(_change) = true

    def timeline
      @timeline ||= @versions.filter_map do |version|
        next unless version.item_type == item_type && version.changeset.key?(attribute)

        from, to = version.changeset.fetch(attribute)
        { at: version.created_at, from:, to: }
      end
    end

    # When the value last moved into its current band. For example, with tier
    # changes B -> A, A -> B, B -> A, this is the date of the last B -> A
    def changed_at(to_band)
      timeline.reverse.take_while { band(it[:to]) == to_band }.last[:at]
    end
  end
end
