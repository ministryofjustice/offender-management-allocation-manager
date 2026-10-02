# frozen_string_literal: true

RSpec.shared_context 'with a significant changes detector' do
  let(:changed_at) { Time.zone.local(2026, 10, 1, 10) }
  let(:offender) { instance_double(MpcOffender, recommended_pom_type: RecommendationService::PRISON_POM) }
  let(:review) { instance_double(SignificantChanges, offender:, allocated_pom_position: RecommendationService::PRISON_POM) }

  before do
    allow(review).to receive(:recommendation_differs_from_allocation?) do
      recommended = offender.recommended_pom_type
      allocated = review.allocated_pom_position
      pom_types = [RecommendationService::PRISON_POM, RecommendationService::PROBATION_POM]

      recommended.in?(pom_types) && allocated.in?(pom_types) && recommended != allocated
    end
  end

  def version(item_type, changes, created_at = changed_at)
    PaperTrail::Version.new(item_type:, event: 'update', created_at:, object_changes: YAML.dump(changes))
  end

  def case_info_version(changes, created_at = changed_at) = version('CaseInformation', changes, created_at)
  def handover_version(changes, created_at = changed_at) = version('CalculatedHandoverDate', changes, created_at)
  def detect(*versions) = described_class.new(review, versions).change
end
