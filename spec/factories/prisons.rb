# frozen_string_literal: true

FactoryBot.define do
  CLOSED_MALE_PRISON_CODES = PrisonService.prison_codes.reject { |x|
    PrisonService::OPEN_PRISON_CODES.include?(x) ||
      PrisonService::ENGLISH_HUB_PRISON_CODES.include?(x) ||
      PrisonService::WOMENS_PRISON_CODES.include?(x) ||
      # Do not create VCR prisons as we create them in rails_helper.rb
      ['LEI', 'PVI'].include?(x)
  }

  factory :prison do
    # rotate around every male closed prison - open and womens prisons have different rules
    sequence(:code) do |c|
      CLOSED_MALE_PRISON_CODES[c % CLOSED_MALE_PRISON_CODES.size]
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
