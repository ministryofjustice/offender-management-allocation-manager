# frozen_string_literal: true

FactoryBot.define do
  factory :sentence_detail, class: 'HmppsApi::SentenceDetail' do
    initialize_with do
      # remove nils (as it confuses HmppsApi::SentenceDetail) and convert dates to strings (just in case test forgets)
      values_hash = attributes.reject { |_k, v| v.nil? }.map { |k, v| [k.to_s, v.to_s] }.to_h
      HmppsApi::SentenceDetail.from_json(values_hash)
    end

    # 1 day after policy start in Wales
    sentenceStartDate { '2019-02-05' }
    releaseDate { "2021-01-28" }
    conditionalReleaseDate { "2022-01-28" }

    trait :welsh_policy_sentence do
      sentenceStartDate { '2019-02-05' }
      conditionalReleaseDate { "2022-01-28" }
      automaticReleaseDate { "2022-01-28" }
    end

    trait :english_policy_sentence do
      sentenceStartDate { '2019-10-05' }
      conditionalReleaseDate { "2022-01-28" }
      automaticReleaseDate { "2022-01-28" }
    end

    trait :handover_in_3_days do
      conditionalReleaseDate { Time.zone.today + 3.days + 7.months + 15.days }
    end

    trait :handover_in_4_days do
      conditionalReleaseDate { Time.zone.today + 4.days + 7.months + 15.days }
    end

    trait :handover_in_8_days do
      conditionalReleaseDate { Time.zone.today + 8.days + 7.months + 15.days }
    end

    trait :handover_in_6_days do
      conditionalReleaseDate { Time.zone.today + 6.days + 7.months + 15.days }
    end

    trait :handover_in_46_days do
      conditionalReleaseDate { Time.zone.today + 46.days + 7.months + 15.days }
    end

    trait :unsentenced do
      sentenceStartDate { nil }
    end

    trait :inside_handover_window do
      conditionalReleaseDate { Time.zone.today + 7.days + 7.months + 15.days }
    end
  end
end



