require 'faker'

FactoryBot.define do
  factory :movement, class: 'Nomis::Movement' do
    skip_create
    from_agency do
      'LEI'
    end

    to_agency do
      'SWI'
    end

    direction_code do
      'IN'
    end

    movement_type do
      'ADM'
    end
  end
end
