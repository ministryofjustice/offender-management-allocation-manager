# frozen_string_literal: true

FactoryBot.define do
  factory :community_data, class: Hash do
    initialize_with { attributes }

    currentTier { 'A' }

    otherIds { { crn: 'X362207'} }

    offenderManagers { [ build(:community_offender_manager) ] }
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
    registerLevel { { code: 'M1' } }
  end
end
