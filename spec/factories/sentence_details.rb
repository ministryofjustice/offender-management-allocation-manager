FactoryBot.define do
  factory :sentence_detail, class: 'HmppsApi::SentenceDetail' do
    initialize_with { HmppsApi::SentenceDetail.from_json(attributes.stringify_keys) }

    releaseDate { "2011-01-28" }
    sentenceStartDate { "2011-01-28" }
    automaticReleaseDate { "2011-01-28" }
    postRecallReleaseDate { "2011-01-28" }
    conditionalReleaseDate { "2011-01-28" }
    homeDetentionCurfewEligibilityDate { "2011-01-28" }
    homeDetentionCurfewActualDate { "2011-01-28" }
    actualParoleDate { "2011-01-28" }
    licenceExpiryDate { "2011-01-28" }
  end

  factory :nomis_sentence_detail, class: Hash do
    initialize_with {
      # remove nil values from hash, so that SentenceDetail#from_json doesn't choke
      attributes.reject { |_k, v| v.nil? }
    }

    releaseDate { "2031-01-19" }
    sentenceStartDate { "2011-01-20" }
    tariffDate { "2031-01-21" }
    automaticReleaseDate { "2031-01-22" }
    postRecallReleaseDate { "2031-01-23" }
    conditionalReleaseDate { "2031-01-24" }
    actualParoleDate { "2031-01-27" }
  end
end



