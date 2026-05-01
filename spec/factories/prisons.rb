# frozen_string_literal: true

FactoryBot.define do
  factory :prison do
    # rotate around every male closed prison - open and womens prisons have different rules
    sequence(:code) do |c|
      prison_codes = PrisonService.prison_codes.reject { |x|
        PrisonService::OPEN_PRISON_CODES.include?(x) ||
          PrisonService::ENGLISH_HUB_PRISON_CODES.include?(x) ||
          PrisonService::WOMENS_PRISON_CODES.include?(x) ||
          %w[LEI PVI].include?(x)
      }

      prison_codes[c % prison_codes.size]
    end

    trait :open do
      sequence(:code) do |c|
        PrisonService::OPEN_PRISON_CODES[c % PrisonService::OPEN_PRISON_CODES.size]
      end
    end
    name{PrisonService::PRISONS[code]&.name}
    prison_type {'mens_closed'}
  end

  factory :womens_prison, parent: :prison do
    sequence(:code) do |c|
      PrisonService::WOMENS_PRISON_CODES[c % PrisonService::WOMENS_PRISON_CODES.size]
    end
    prison_type {'womens'}
  end
end
