FactoryBot.define do
  factory :pom_detail do
    status do 'active' end
    working_pattern do 1 end
    # add 1 to prevent a nomis_staff_id of zero
    sequence(:nomis_staff_id) do |x| x + 1 end

    trait :inactive do
      status { 'inactive' }
    end

    trait :active do
      status { 'active' }
    end

    trait :unavailable do
      status { 'unavailable' }
    end
  end

  class Elite2POM
    attr_accessor :position, :staffId, :emails, :firstName, :lastName
  end

  factory :pom, class: 'Elite2POM' do
    position do 'PRO' end
    sequence(:emails) do |x| ["staff#{x}@justice.gov.uk"]  end
    sequence(:staffId) do |x| x + 1  end

    trait :probation_officer do
      position { 'PO' }
    end

    trait :prison_officer do
      position { 'PRO' }
    end
  end
end
