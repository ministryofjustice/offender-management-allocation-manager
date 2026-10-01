# frozen_string_literal: true

class SignificantChanges
  # Significant if the tier changes to or from A
  class TierDetector < Detector
    tracks :tier, label: 'Tier', item_type: 'CaseInformation', attribute: 'tier'

  private

    def band(tier)
      (tier == 'A' if tier.present?)
    end
  end
end
