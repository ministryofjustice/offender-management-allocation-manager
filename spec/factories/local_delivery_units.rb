# frozen_string_literal: true

FactoryBot.define do
  factory :local_delivery_unit do
    sequence(:code) { |seq| "LDU#{seq}" }
    name { Faker::Address.county } # LDUs tend to be named after a county (e.g. Kent)
    email_address { Faker::Internet.email }
    enabled { true }
    country { 'England' }

    trait :disabled do
      enabled { false }
    end
  end
end
