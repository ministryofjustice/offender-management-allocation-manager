module Ndelius
  class FakeRecord
    TIER_A = 'A'
    TIER_B = 'B'
    TIER_C = 'C'
    TIER_D = 'D'

    NPS_CASE_ALLOCATION = 'NPS'
    CRC_CASE_ALLOCATION = 'CRC'

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def self.generate(nomis_id)
      last_letter = nomis_id.split('').last

      case last_letter
      when 'A', 'B', 'C', 'D'
        new(TIER_A, NPS_CASE_ALLOCATION, nomis_id)
      when 'E', 'F', 'G', 'H'
        new(TIER_B, NPS_CASE_ALLOCATION, nomis_id)
      when 'I', 'J', 'K', 'L'
        new(TIER_C, CRC_CASE_ALLOCATION, nomis_id)
      when 'M', 'N', 'O', 'P'
        new(TIER_D, CRC_CASE_ALLOCATION, nomis_id)
      when 'Q', 'R', 'S', 'T'
        raise NoTierException
      when 'U', 'V', 'W', 'X'
        raise MultipleRecordException
      when 'Y', 'Z'
        raise NoRecordException
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    attr_reader :tier, :case_allocation, :nomis_id

    def initialize(tier, case_allocation, nomis_id)
      @tier = tier
      @case_allocation = case_allocation
      @nomis_id = nomis_id
    end
  end

  class NoTierException < StandardError; end

  class MultipleRecordException < StandardError; end

  class NoRecordException < StandardError; end
end
