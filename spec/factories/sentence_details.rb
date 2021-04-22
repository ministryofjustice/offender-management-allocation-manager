# frozen_string_literal: true

FactoryBot.define do
  factory :sentence_detail, class: 'HmppsApi::SentenceDetail' do
    initialize_with do
      # remove nils (as it confuses HmppsApi::SentenceDetail) and convert dates to strings (just in case test forgets)
      values_hash = attributes.except(:imprisonmentStatus).reject { |_k, v| v.nil? }.map { |k, v| [k.to_s, v.to_s] }.to_h
      HmppsApi::SentenceDetail.new values_hash,
                                   attributes.stringify_keys
    end

    imprisonmentStatus { 'SEC90' }
    recall { false }

    # 1 day after policy start in Wales
    sentenceStartDate { '2019-02-05' }
    releaseDate { "2021-01-28" }
    conditionalReleaseDate { "2022-01-28" }

    trait :blank do
      sentenceStartDate { nil }
      releaseDate { nil }
      conditionalReleaseDate { nil }
    end

    trait :welsh_policy_sentence do
      sentenceStartDate { '2019-02-05' }
      conditionalReleaseDate { "2022-01-28" }
      automaticReleaseDate { "2022-01-28" }
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
      paroleEligibilityDate { Time.zone.today + 8.months + 3.days }
    end

    trait :handover_in_4_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 4.days }
    end

    trait :handover_in_8_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 8.days }
    end

    trait :handover_in_6_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 6.days }
    end

    trait :handover_in_46_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 46.days }
    end

    trait :handover_in_28_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 28.days }
    end

    trait :handover_in_14_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 14.days }
    end

    trait :handover_in_21_days do
      paroleEligibilityDate { Time.zone.today + 8.months + 21.days }
    end

    trait :unsentenced do
      sentenceStartDate { nil }
    end

    trait :inside_handover_window do
      conditionalReleaseDate { Time.zone.today + 7.days + 7.months }
    end

    trait :indeterminate do
      imprisonmentStatus { 'LIFE' }
      tariffDate { Time.zone.today + 1.year}
     end

    trait :outside_early_allocation_window do
      conditionalReleaseDate { Time.zone.today + 19.months }
    end

    trait :determinate do
      imprisonmentStatus {'SEC90'}
    end

    trait :indeterminate do
      imprisonmentStatus {'LIFE'}
    end

    trait :indeterminate_recall do
      imprisonmentStatus {'LR_LIFE'}
      recall { true }
    end

    trait :determinate_recall do
      imprisonmentStatus {'LR_EPP'}
      recall { true }
    end

    trait :civil_sentence do
      imprisonmentStatus {'CIVIL'}
    end
  end
end



