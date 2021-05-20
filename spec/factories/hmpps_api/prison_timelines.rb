FactoryBot.define do
  factory :hmpps_api_prison_timeline, class: 'HmppsApi::PrisonTimeline' do
    initialize_with do
      HmppsApi::PrisonTimeline.new attributes.fetch(:movements, [])
    end
  end
end
