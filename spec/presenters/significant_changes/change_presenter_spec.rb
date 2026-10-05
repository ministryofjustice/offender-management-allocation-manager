require 'rails_helper'

RSpec.describe SignificantChanges::ChangePresenter do
  subject(:presenter) { described_class.new(change, review:) }

  let(:changed_at) { Time.zone.local(2026, 9, 30, 10) }
  let(:change) { SignificantChanges::Change.new(type:, label: '', from_value:, to_value:, changed_at:) }
  let(:review) { instance_double(SignificantChanges) }

  context 'with a tier change' do
    let(:type) { :tier }
    let(:from_value) { 'B' }
    let(:to_value) { 'A' }

    it 'presents the title, date and values without a handover explanation' do
      expect(presenter).to have_attributes(type: :tier, title: 'Tier change', changed_at: '30 Sep 2026',
                                           from_value: 'Tier B', to_value: 'Tier A', explanation: nil)
    end
  end

  context 'with a ROSH change' do
    let(:type) { :rosh }
    let(:from_value) { 'MEDIUM' }
    let(:to_value) { 'VERY_HIGH' }

    it 'presents readable ROSH values' do
      expect(presenter).to have_attributes(title: 'ROSH change', from_value: 'Medium',
                                           to_value: 'Very high', explanation: nil)
    end
  end

  context 'with a handover change' do
    let(:type) { :handover }
    let(:from_value) { Date.new(2026, 8, 3) }
    let(:to_value) { Date.new(2027, 4, 20) }
    let(:review) { instance_double(SignificantChanges, allocated_pom_position: allocated) }
    let(:allocated) { RecommendationService::PRISON_POM }

    it 'presents the title and formatted dates' do
      expect(presenter).to have_attributes(title: 'Change to date when COM becomes responsible',
                                           from_value: '03 Aug 2026', to_value: '20 Apr 2027')
    end

    it 'explains changing from a prison POM to a probation POM' do
      expect(presenter.explanation).to eq(
        'The community probation team will take responsibility for this person later, ' \
        'so they may no longer need a prison POM. Check whether a probation POM should be allocated instead.'
      )
    end

    context 'when a probation POM is allocated' do
      let(:allocated) { RecommendationService::PROBATION_POM }

      it 'explains changing from a probation POM to a prison POM' do
        expect(presenter.explanation).to eq(
          'The community probation team will take responsibility for this person later, ' \
          'so they may no longer need a probation POM. Check whether a prison POM should be allocated instead.'
        )
      end
    end
  end
end
