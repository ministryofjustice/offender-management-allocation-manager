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
    automaticReleaseDate { "2022-01-28" }
    postRecallReleaseDate { "2021-01-28" }
    conditionalReleaseDate { "2022-01-28" }
    actualParoleDate { "2021-01-28" }
    licenceExpiryDate { "2021-01-28" }

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
  end
end



