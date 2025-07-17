FactoryBot.define do
  factory :pom_detail do
    status { 'active' }
    working_pattern { 1 }
    # don't want a nomis_staff_id of zero
    sequence(:nomis_staff_id) { |x| x + 1000 }

    trait :inactive do
      status { 'inactive' }
    end

    trait :active do
      status { 'active' }
    end

    trait :unavailable do
      status { 'unavailable' }
    end

    trait :part_time do
      working_pattern { 0.5 }
    end
  end

  class Elite2POM
    attr_accessor :position, :staffId, :emails, :firstName, :lastName, :positionDescription, :status, :primaryEmail
    attr_writer :agencyId

    def first_name
      firstName
    end

    def last_name
      lastName
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    def staff_id
      staffId
    end

    def email_address
      emails.present? ? emails.first : primaryEmail
    end
  end

  factory :pom, class: 'Elite2POM' do
    position { 'PRO' }
    emails { [Faker::Internet.email] }
    sequence(:staffId) { |x| x + 1000  }
    status { 'ACTIVE' }

    primaryEmail { emails ? emails.first : Faker::Internet.email }

    firstName { Faker::Name.first_name }
    # The POM's last name is titleized as it's passed through StaffMember, e.g. "McDonald" becomes "Mcdonald"
    # So we also .titleize the last name here to avoid breaking tests
    lastName { Faker::Name.last_name.titleize }
    positionDescription { Faker::Company.type }

    trait :probation_officer do
      position { 'PO' }
    end

    trait :prison_officer do
      position { 'PRO' }
    end
  end
end
