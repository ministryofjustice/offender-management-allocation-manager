# frozen_string_literal: true

FactoryBot.define do
  factory :sentence_detail, class: 'HmppsApi::SentenceDetail' do
    initialize_with do
      # remove nils (as it confuses HmppsApi::SentenceDetail) and convert dates to strings (just in case test forgets)
      values_hash = attributes.reject { |_k, v| v.nil? }.map { |k, v| [k.to_s, v.to_s] }.to_h
      HmppsApi::SentenceDetail.from_json(values_hash)
    end

    sentenceStartDate { '2019-02-05' }
    releaseDate { "2021-01-28" }
    automaticReleaseDate { "2022-01-28" }
    postRecallReleaseDate { "2021-01-28" }
    conditionalReleaseDate { "2022-01-28" }
    actualParoleDate { "2021-01-28" }
    licenceExpiryDate { "2021-01-28" }
  end

  factory :nomis_sentence_detail, class: Hash do
    initialize_with {
      # remove nil values from hash, so that SentenceDetail#from_json doesn't choke
      attributes.reject { |_k, v| v.nil? }
    }

    sentenceStartDate { "2011-01-20" }
    releaseDate { "2031-01-19" }
    tariffDate { "2031-01-21" }
    automaticReleaseDate { "2031-01-22" }
    postRecallReleaseDate { "2031-01-23" }
    conditionalReleaseDate { "2031-01-24" }
    actualParoleDate { "2031-01-27" }
  end
end



