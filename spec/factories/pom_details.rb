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
    attr_accessor :position, :staffId, :emails, :firstName, :lastName, :positionDescription, :status

    def full_name
      "#{lastName}, #{firstName}"
    end

    def staff_id
      staffId
    end
  end

  factory :pom, class: 'Elite2POM' do
    position { 'PRO' }
    sequence(:emails) { |x| ["staff#{x}@justice.gov.uk"]  }
    sequence(:staffId) { |x| x + 1000  }
    status { 'ACTIVE' }

    firstName { Faker::Name.first_name }
    lastName { Faker::Name.last_name }
    positionDescription { Faker::Company.type }

    trait :probation_officer do
      position { 'PO' }
    end

    trait :prison_officer do
      position { 'PRO' }
    end
  end
end
