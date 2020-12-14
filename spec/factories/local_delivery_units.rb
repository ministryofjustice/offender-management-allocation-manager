# frozen_string_literal: true

FactoryBot.define do
  factory :local_delivery_unit do
    sequence(:code) { |seq| "LDU#{seq}" }
    name { "MyString" }
    email_address { Faker::Internet.email }
    enabled { false }
    country { 'England' }
  end
end
