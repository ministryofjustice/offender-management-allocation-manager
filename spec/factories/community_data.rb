# frozen_string_literal: true

FactoryBot.define do
  factory :community_data, class: Hash do
    initialize_with { attributes }

    currentTier { 'A' }

    otherIds { { crn: 'X362207'} }

    offenderManagers { [ build(:community_offender_manager) ] }

    trait :crc do
      enhancedResourcing { false }
    end

    trait :nps do
      enhancedResourcing { true }
    end
  end

  factory :community_offender_manager, class: Hash do
    initialize_with { attributes }

    active { true }
    probationArea { { nps: true } }
    staff { { unallocated: false, surname: 'Jones', forenames: 'Ruth Mary' } }
  end

  factory :community_registration, class: Hash do
    initialize_with { attributes }

    active { true }

    trait :mappa_2 do
      registerLevel {
        {
            code: 'M2',
            description: 'MAPPA Level 2'
        }
      }
    end
  end

  factory :community_all_offender_managers_datum, class: Hash do
    transient do
      forenames { Faker::Name.first_name }
      surname { Faker::Name.last_name }
      email { Faker::Internet.safe_email }
    end

    initialize_with { attributes }
    isResponsibleOfficer { true }
    isPrisonOffenderManager { false }
    isUnallocated { false }
    staff { { 'forenames' => forenames, 'surname' => surname, 'email' => email } }
  end
end
