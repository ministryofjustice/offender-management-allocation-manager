FactoryBot.define do
  factory :probation_record, class: Hash do
    initialize_with { attributes }

    manager { { team: { local_delivery_unit: {} }, name: {} } }
    rosh { {} }

    transient do
      offender_no { 'XY123Z' }
      crn { 'ABC123' }
      tier { 'A' }
      resourcing { 'ENHANCED' }
      mappa_level { 0 }
      vlo_assigned { false }
      team_code { 'A000BCD' }
      team_description { 'A team description' }
      ldu_code { 'LDU123' }
      ldu_description { 'An LDU description' }
      com_code { 'COM123' }
      com_forename { 'Edgar' }
      com_middle_name { 'Allan' }
      com_surname { 'Poe' }
      com_email { 'edgar@poe.me' }
      rosh_level { 'HIGH' }
      rosh_start_date { Date.new(2026, 3, 14) }
    end

    after(:build) do |h, evaluator|
      h[:noms_id] = evaluator.offender_no
      h[:crn] = evaluator.crn
      h[:tier] = evaluator.tier
      h[:resourcing] = evaluator.resourcing
      h[:mappa_level] = evaluator.mappa_level
      h[:vlo_assigned] = evaluator.vlo_assigned
      h[:manager][:team][:code] = evaluator.team_code
      h[:manager][:team][:description] = evaluator.team_description
      h[:manager][:team][:local_delivery_unit][:code] = evaluator.ldu_code
      h[:manager][:team][:local_delivery_unit][:description] = evaluator.ldu_description
      h[:manager][:name][:forename] = evaluator.com_forename
      h[:manager][:name][:middle_name] = evaluator.com_middle_name
      h[:manager][:name][:surname] = evaluator.com_surname
      h[:manager][:email] = evaluator.com_email
      h[:rosh][:level] = evaluator.rosh_level
      h[:rosh][:start_date] = evaluator.rosh_start_date
    end

    trait :nil_ldu do
      after(:build) do |h|
        h[:manager][:team][:local_delivery_unit][:code] = nil
        h[:manager][:team][:local_delivery_unit][:description] = nil
      end
    end

    trait :nil_rosh do
      after(:build) do |h|
        h[:rosh][:level] = nil
        h[:rosh][:start_date] = nil
      end
    end

    trait :no_com do
      after(:build) do |h|
        h[:manager].delete(:name)
        h[:manager].delete(:code)
        h[:manager].delete(:email)
      end
    end
  end
end
