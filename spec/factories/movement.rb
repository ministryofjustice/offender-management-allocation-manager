FactoryBot.define do
  factory :movement, class: 'Nomis::Movement' do
    initialize_with do
      Nomis::Movement.from_json(attributes.stringify_keys)
    end

    trait :rotl do
      movementType { 'TAP' }
      directionCode  { 'OUT' }
    end

    trait :out do
      directionCode { 'OUT' }
      movementType { 'REL' }
    end

    fromAgency do
      'LEI'
    end

    sequence(:createDateTime) do |seq|
      (Time.zone.today - seq.days).to_s
    end

    toAgency do
      'SWI'
    end

    # default movement is 'in' (IN/ADM)
    directionCode { 'IN' }
    movementType { 'ADM' }
  end
end
