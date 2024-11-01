# frozen_string_literal: true

FactoryBot.define do
  factory :nomis_offender, class: Hash do
    initialize_with {
      # convert values to JSON primitives (e.g. Date to String)
      attrs = JSON.parse(attributes.to_json).deep_symbolize_keys
      attrs.except(:sentence).merge(attrs.fetch(:sentence, {}))
    }

    inOutStatus { 'IN' }
    imprisonmentStatus { 'SENT03' }
    prisonId { 'LEI' }
    supportingPrisonId { 'LEI' }
    restrictedPatient { false }

    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    cellLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    prisonerNumber { generate :nomis_offender_id }
    legalStatus { 'SENTENCED' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    category { attributes_for(:offender_category, :cat_c) }

    sentence do
      attributes_for :sentence_detail
    end

    complexityLevel { 'medium' }

    sequence(:bookingId) { |c| c + 100_000 }

    # Use in conjunction with the :rotl trait on :movement
    trait :rotl do
      inOutStatus { 'OUT' }
      lastMovementTypeCode { 'TAP' }
    end

    created {Date.new }
  end

  factory :offender do
    nomis_offender_id

    trait :enhanced_handover do
      case_information { create(:case_information, enhanced_resourcing: true) }
    end

    trait :normal_handover do
      case_information { create(:case_information, enhanced_resourcing: false) }
    end
  end

  factory :mpc_offender do
    initialize_with { MpcOffender.new(prison: attributes.fetch(:prison),
                                      offender: attributes.fetch(:offender),
                                      prison_record: attributes.fetch(:prison_record)) }


    # NOTE: It is advised to freeze time at 20th May 2024 when using the persons
    # This makes the test data easier to read
    #
    # Timecop.freeze(Time.local(2024, 5, 20))
    #
    trait :with_persona do
      isp { false }
      ted { nil }
      ped { nil }
      mappa_level { nil }
      recall { nil }

      initialize_with {
        sentence_data = attributes_for(:sentence_detail, (isp ? :indeterminate : :determinate), recall:)
        api_offender = HmppsApi::Offender.new(
          category: nil,
          latest_temp_movement: nil,
          complexity_level: nil,
          offender: attributes_for(:nomis_offender,
            sentence: sentence_data,
            **sentence_data,
            tariffDate: ted,
            paroleEligibilityDate: ped,
          ).deep_stringify_keys,
          movements: []
        )

        MpcOffender.new(
          prison: build(:prison),
          offender: create(:offender,
            nomis_offender_id: api_offender.offender_no,
            case_information: build(:case_information, mappa_level:)
          ),
          prison_record: api_offender
        )
      }
    end

    # Robin Hoodwink has a Tariff expiry date (TED) of 20th January 2025 = COM responsibility
    # (handover from POM to COM was 12 months prior to TED / 20/1/24)
    trait :robin_hoodwink do
      isp { true }
      ted { Date.parse("20th January 2025") }
    end

    # Clarke Kentish has had two previous parole hearings,
    # the outcome of his last parole was recorded on
    # 1st February 2024 - ‘move to open conditions’.
    # He has a Target Hearing Date (THD) of 30th January 2025 = COM responsibility
    # (under 12 months)
    trait :clarke_kentish do
      isp { true }

      after(:build) do |mpc_offender|
        hearing_outcomes = [
          { hearing_outcome_received_on: Date.parse("1st February 2024") - 1.year,
            hearing_outcome: "Open Conditions - Rejected [*]" },
          { hearing_outcome_received_on: Date.parse("1st February 2024"),
            hearing_outcome: "Open Conditions - Accepted [*]",
            target_hearing_date: Date.parse("30th January 2025") },
        ]
        hearing_outcomes.each do |hearing_outcome|
          create(:parole_review,
            nomis_offender_id: mpc_offender.nomis_offender_id,
            **hearing_outcome
          )
        end
      end
    end

    # Jane Heart has had one Parole hearing,
    # the outcome was recorded on 12th May 2024 - ‘remain in closed’.
    # She has a Target Hearing Date (THD) for 12th May 2026.
    # She is MAPPA Level 1 = POM responsibility
    # (Over 12 months)
    trait :jane_heart do
      isp { true }
      mappa_level { 1 }

      after(:build) do |mpc_offender|
        create(:parole_review,
          nomis_offender_id: mpc_offender.nomis_offender_id,
          hearing_outcome_received_on: Date.parse("12th May 2024"),
          hearing_outcome: "Stay In Closed [*]",
          target_hearing_date: Date.parse("12th May 2026")
        )
      end
    end

    # Adam Leant has a Tariff expiry date (TED) of 6th November 2045 = POM responsibility
    # (Pre-handover)
    trait :adam_leant do
      isp { true }
      ted { Date.parse("6th November 2045") }
    end

    # Paul McCain has had three previous parole hearings,
    # the outcome of his last parole was recorded on 15th May 2024 - ‘release’
    # = COM responsibility (to be released)
    trait :paul_mccain do
      isp { true }

      after(:build) do |mpc_offender|
        hearing_outcomes = [
          { hearing_outcome_received_on: Date.parse("15th May 2022"),
            hearing_outcome: "Not Applicable" },
          { hearing_outcome_received_on: Date.parse("15th May 2023"),
            hearing_outcome: "Not Applicable" },
          { hearing_outcome_received_on: Date.parse("15th May 2024"),
            hearing_outcome: "Release [*]", target_hearing_date: Date.parse("15th May 2023")  },
        ]
        hearing_outcomes.each do |hearing_outcome|
          create(:parole_review,
            nomis_offender_id: mpc_offender.nomis_offender_id,
            **hearing_outcome
          )
        end
      end
    end

    # Peggy Sueis has had one Parole hearing, the outcome was recorded
    # on 30th April 2024 - ‘remain in closed’.
    # She has a Target Hearing Date (THD) for 16th May 2027.
    # She is MAPPA Level 3 = COM responsibility
    # (Mappa level 3)
    trait :peggy_sueis do
      isp { true }
      mappa_level { 3 }

      after(:build) do |mpc_offender|
        create(:parole_review,
          nomis_offender_id: mpc_offender.nomis_offender_id,
          hearing_outcome_received_on: Date.parse("30th April 2024"),
          hearing_outcome: "Stay In Closed [*]",
          target_hearing_date: Date.parse("16th May 2027")
        )
      end
    end

    # Nelly Theeleph has been recalled back to prison, ISP prisoner.
    # After her Recall hearing outcome which was recorded on 18th May 2024;
    # she now has a THD for 10th May 2025 = COM responsibility
    # (under 12 months)
    trait :nelly_theeleph do
      isp { true }
      recall { true }

      after(:build) do |mpc_offender|
        create(:parole_review,
          nomis_offender_id: mpc_offender.nomis_offender_id,
          hearing_outcome_received_on: Date.parse("18th May 2024"),
          hearing_outcome: "Stay In Closed [*]",
          target_hearing_date: Date.parse("10th May 2025")
        )
      end
    end

    # Seymore Tress has been recalled back to prison, ISP prisoner.
    # After his Recall hearing outcome which was recorded on 18th January 2023;
    # she now has a THD for 10th May 2025 = COM responsibility
    # (Handover to COM on 10th May 2024)
    trait :seymore_tress do
      isp { true }
      recall { true }

      after(:build) do |mpc_offender|
        create(:parole_review,
          nomis_offender_id: mpc_offender.nomis_offender_id,
          hearing_outcome_received_on: Date.parse("18th January 2023"),
          hearing_outcome: "Stay In Closed [*]",
          target_hearing_date: Date.parse("10th May 2025")
        )
      end
    end
  end
end
