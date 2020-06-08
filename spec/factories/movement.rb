FactoryBot.define do
  factory :movement, class: 'Nomis::Movement' do
    skip_create

    initialize_with do
      Nomis::Movement.from_json(attributes.stringify_keys)
    end

    trait :tap do
      movementType do 'TAP' end
      directionCode  { 'OUT' }
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

    directionCode do
      'IN'
    end

    movementType do
      'ADM'
    end
  end
end
