require 'rails_helper'

RSpec.describe ComplexityLevelHelper, type: :helper do
  let(:updated) { Complexity.new(level: updated_level, reason: 'bla bla bla') }
  let(:subject) { helper.display_complexity_change_info(previous_complexity_level: previous, updated_complexity_level: updated.level) }

  context 'when complexity level has been updated from low to high' do
    let(:previous) { 'low' }
    let(:updated_level) { 'high' }

    it 'renders the complexity_level_increase_to_high partial' do
      expect(subject).to include('As the complexity of need level has increased from low to high')
    end
  end

  context 'when complexity level has been updated from medium to high' do
    let(:previous) { 'medium' }
    let(:updated_level) { 'high' }

    it 'renders the complexity_level_increase_to_high partial' do
      expect(subject).to include('As the complexity of need level has increased from medium to high')
    end
  end

  context 'when complexity level has been updated from high to low' do
    let(:previous) { 'high' }
    let(:updated_level) { 'low' }

    it 'renders the complexity_level_lowered_from_high partial' do
      expect(subject).to include('As the complexity of need level has been lowered to from high to low')
    end
  end

  context 'when complexity level has been updated from high to medium' do
    let(:previous) { 'high' }
    let(:updated_level) { 'medium' }

    it 'renders the complexity_level_lowered_from_high partial' do
      expect(subject).to include('As the complexity of need level has been lowered to from high to medium')
    end
  end

  context 'when complexity level has been changed from medium to low' do
    let(:previous) { 'medium' }
    let(:updated_level) { 'low' }

    it 'renders the complexity_level_lowered_from_high partial' do
      expect(subject).to include('You may need to review the POM for this case and reallocate if necessary.')
    end
  end

  context 'when complexity level has not been changed' do
    let(:previous) { 'medium' }
    let(:updated_level) { 'medium' }

    it 'redirects to the prisoner profile page' do
      expect(subject).to include('You may need to review the POM for this case and reallocate if necessary.')
    end
  end
end
