# frozen_string_literal: true

FactoryBot.define do
  factory :sentence_detail, class: 'HmppsApi::SentenceDetail' do
    initialize_with do
      # run attributes through JSON for a more realistic payload
      values_hash = JSON.parse(attributes.to_json)
      HmppsApi::SentenceDetail.new values_hash
    end

    imprisonmentStatus { 'SEC90' }
    imprisonmentStatusDescription { 'Did a really bad thing' }
    indeterminateSentence { false }
    recall { false }

    # 1 day after policy start in Wales
    sentenceStartDate { '2019-02-05' }
    releaseDate { Time.zone.today + 2.years }
    conditionalReleaseDate { Time.zone.today + 1.year }

    trait :blank do
      sentenceStartDate { nil }
      releaseDate { nil }
      conditionalReleaseDate { nil }
    end

    trait :welsh_policy_sentence do
      sentenceStartDate { '2019-02-05' }
    end

    trait :welsh_open_policy do
      sentenceStartDate { '2020-10-20' }
    end

    trait :english_policy_sentence do
      sentenceStartDate { '2019-10-05' }
      conditionalReleaseDate { "2022-01-28" }
      automaticReleaseDate { "2022-01-28" }
    end

    # We use PED here (assuming determinate) so that we don't suffer
    # the 15.days / half-month problem is places where we don't care
    trait :handover_in_3_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 3.days }
    end

    trait :handover_in_4_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 4.days }
    end

    trait :handover_in_8_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 8.days }
    end

    trait :handover_in_6_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 6.days }
    end

    trait :handover_in_46_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 46.days }
    end

    trait :handover_in_28_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 28.days }
    end

    trait :handover_in_14_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 14.days }
    end

    trait :handover_in_21_days do
      paroleEligibilityDate { Time.zone.today + 12.months + 21.days }
    end

    trait :after_handover do
      conditionalReleaseDate { Time.zone.today + 7.months }
    end

    trait :unsentenced do
      sentenceStartDate { nil }
    end

    trait :indeterminate do
      indeterminateSentence { true }
      releaseDate { nil }
      tariffDate { Time.zone.today + 1.year + 4.months }
    end

    trait :outside_early_allocation_window do
      conditionalReleaseDate { Time.zone.today + 19.months }
    end

    trait :determinate do
      indeterminateSentence { false }
    end

    trait :recall do
      recall { true }
    end

    trait :approaching_parole do
      # If this ever fails, check mpc_offender#approaching_parole? logic
      paroleEligibilityDate { 1.day.from_now }
    end

    trait :indeterminate_recall do
      indeterminateSentence { true }
      recall { true }
    end

    trait :determinate_recall do
      indeterminateSentence { false }
      recall { true }
    end

    trait :civil_sentence do
      imprisonmentStatus {'CIVIL'}
    end

    trait :less_than_10_months_to_serve do
      sentenceStartDate { Time.zone.today - 2.months }
      conditionalReleaseDate { Time.zone.today + 7.months }
    end

    # the default release date and conditional release date will force the offender to be POM supporting and requiring a COM
    # this trait makes sure the determinate offender has a release date long into the future
    trait :determinate_release_in_three_years do
      releaseDate { Time.zone.today + 3.years }
      conditionalReleaseDate { Time.zone.today + 3.years }
    end

    # this is based on logic taken from a potentially out of date test, update if required
    trait :outside_omic_policy do
      releaseDate { 3.years.from_now }
      sentenceStartDate { nil }
    end
  end
end
