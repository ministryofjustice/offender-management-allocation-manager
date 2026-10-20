# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JourneyReturn do
  controller(ApplicationController) do
    include JourneyReturn # rubocop:disable RSpec/DescribedClass

    public :remember_journey_source, :stored_journey_path_for

    def active_prison_id = 'LEI'
  end

  let(:default_path) { '/default' }
  let(:review_allocations_path) { review_allocations_prison_prisoners_path('LEI') }

  before { freeze_time }

  def take(offender_id: 'A1111AA', journey: :allocation)
    controller.stored_journey_path_for(journey, offender_id:, default: default_path)
  end

  describe '#remember_journey_source' do
    it 'stores an allowlisted source from the from param by default' do
      controller.params[:from] = 'review_allocations'
      controller.remember_journey_source(:allocation, offender_id: 'A1111AA')

      expect(take).to eq(review_allocations_path)
    end

    it 'ignores unknown sources' do
      controller.remember_journey_source(:allocation, offender_id: 'A1111AA', source: 'https://evil.example')

      expect(session[described_class::SESSION_KEY]).to be_nil
      expect(take).to eq(default_path)
    end

    it 'ignores a missing source' do
      controller.remember_journey_source(:allocation, offender_id: 'A1111AA')

      expect(session[described_class::SESSION_KEY]).to be_nil
    end

    it 'stores only serialisable strings and integers in the session' do
      controller.remember_journey_source(:allocation, offender_id: 'A1111AA', source: :review_allocations)

      expect(session[described_class::SESSION_KEY]).to eq(
        'allocation:LEI:A1111AA' => { 'source' => 'review_allocations', 'expires_at' => described_class::SOURCE_TTL.from_now.to_i }
      )
    end
  end

  describe '#stored_journey_path_for' do
    before do
      controller.remember_journey_source(:allocation, offender_id: 'A1111AA', source: 'review_allocations')
    end

    it 'returns the source path only once' do
      expect(take).to eq(review_allocations_path)
      expect(take).to eq(default_path)
    end

    it 'is scoped to the offender' do
      expect(take(offender_id: 'B2222BB')).to eq(default_path)
      expect(take).to eq(review_allocations_path)
    end

    it 'is scoped to the journey' do
      expect(take(journey: :other)).to eq(default_path)
      expect(take).to eq(review_allocations_path)
    end

    it 'builds paths that need the offender as well as the prison' do
      stub_const("#{described_class}::SOURCE_PATHS", {
        'prisoner_profile' => ->(prison_id:, offender_id:) { prison_prisoner_path(prison_id, offender_id) },
      })
      controller.remember_journey_source(:allocation, offender_id: 'B2222BB', source: 'prisoner_profile')

      expect(take(offender_id: 'B2222BB')).to eq(prison_prisoner_path('LEI', 'B2222BB'))
    end

    it 'returns the default once the source has expired' do
      travel_to(described_class::SOURCE_TTL.from_now + 1.second) do
        expect(take).to eq(default_path)
      end
    end

    it 'prunes expired entries' do
      travel_to(described_class::SOURCE_TTL.from_now + 1.second) do
        controller.remember_journey_source(:allocation, offender_id: 'B2222BB', source: 'review_allocations')
      end

      expect(session[described_class::SESSION_KEY].keys).to eq(['allocation:LEI:B2222BB'])
    end
  end
end
