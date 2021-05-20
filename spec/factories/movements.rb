FactoryBot.define do
  factory :movement, class: 'HmppsApi::Movement' do
    initialize_with do
      HmppsApi::Movement.from_json(attributes.stringify_keys.map { |k, v| [k, v.to_s] }.to_h)
    end

    offenderNo { 'G6543GH' }

    trait :rotl do
      movementType { 'TAP' }
      directionCode  { 'OUT' }
    end

    trait :transfer do
      movementType { 'TRN' }
    end

    trait :out do
      directionCode { 'OUT' }
    end

    trait :release do
      directionCode { 'OUT' }
      toAgency { MovementService::RELEASE_MOVEMENT_CODE }
      movementType { 'REL' }
    end

    fromAgency do
      'LEI'
    end

    # This should be far enough in the past so that the offender isn't considered a 'new arrival' by default
    sequence(:movementDate) do |seq|
      ((Time.zone.today - 5.years) + seq.days)
    end

    movementTime { '04:45:00' }

    toAgency do
      'SWI'
    end

    # default movement is 'in' (IN/ADM)
    directionCode { 'IN' }
    movementType { 'ADM' }
  end
end
