# frozen_string_literal: true

class SignificantChanges
  # Significant if the ROSH level moves between Low/Medium and High/Very_high
  class RoshDetector < Detector
    tracks :rosh, label: 'ROSH', item_type: 'CaseInformation', attribute: 'rosh_level'

  private

    def band(rosh_level)
      { 'LOW' => :low, 'MEDIUM' => :low, 'HIGH' => :high, 'VERY_HIGH' => :high }[rosh_level]
    end
  end
end
