FactoryBot.define do
  factory :assessment_api_response, class: Hash do
    initialize_with { attributes }

    assessmentId { Faker::Number.number }
    refAssessmentVersionCode { "LAYER3" }
    refAssessmentVersionNumber { "1" }
    refAssessmentId { 4 }
    assessmentType { "LAYER3" }
    assessmentStatus { "COMPLETE" }
    historicStatus { "CURRENT" }
    refAssessmentOasysScoringAlgorithmVersion { 3 }
    assessorName { Faker::Name.name }
    created { "2012-12-10T15:48:30" }
    completed { Faker::Time.backward }
  end
end
