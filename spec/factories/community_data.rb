# frozen_string_literal: true

FactoryBot.define do
  factory :community_data, class: Hash do
    initialize_with { attributes }

    currentTier { 'A' }

    otherIds { { crn: 'X362207'} }

    offenderManagers { [ build(:community_offender_manager) ] }

    trait :normal_handover do
      enhancedResourcing { false }
    end

    trait :enhanced_handover do
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

    trait :type_invi do
      type {
        { code: 'INVI' }
      }
    end

    trait :type_daso do
      type {
        { code: 'DASO' }
      }
    end
  end

  factory :community_all_offender_managers_datum, class: Hash do
    transient do
      forenames { Faker::Name.first_name }
      surname { Faker::Name.last_name }
      email { Faker::Internet.email }
      ldu_code { Faker::Alphanumeric.alpha(number: 7) }
      team_name { Faker::Alphanumeric.alpha(number: 5) }
    end

    initialize_with { attributes }
    isResponsibleOfficer { true }
    isPrisonOffenderManager { false }
    isUnallocated { false }
    staff { { 'forenames' => forenames, 'surname' => surname, 'email' => email }.compact_blank }
    team { { 'description' => team_name, 'localDeliveryUnit' => { code: ldu_code }.compact_blank }.compact_blank }
  end
end
