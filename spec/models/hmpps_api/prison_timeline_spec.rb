require 'rails_helper'

RSpec.describe HmppsApi::PrisonTimeline, type: :model do
  let(:p1) { build(:prison).code }
  let(:p2) { build(:prison).code }
  let(:p3) { build(:prison).code }
  let(:p4) { build(:prison).code }
  let(:unknown_code) { 'XYZ' }

  let(:model) do
    described_class.new([
      build(:movement, movementDate: one_month_ago, toAgency: p1),
      build(:movement, movementDate: last_fortnight, toAgency: p2),
      build(:movement, movementDate: last_week, toAgency: p3),
      build(:movement, :transfer, :out, movementDate: three_days_ago, toAgency: p4),
      build(:movement, :transfer, movementDate: today, toAgency: unknown_code),
    ])
  end

  let(:today) { Date.new(2024, 3, 15) }
  let(:tomorrow) { today + 1.day }
  let(:last_fortnight) { today - 14.days }
  let(:two_weeks_ago) { last_fortnight.in_time_zone + 12.hours }
  let(:last_week) { today - 7.days }
  let(:three_days_ago) { today - 3.days }
  let(:one_month_ago) { today - 1.month }

  context 'when today' do
    subject do
      model.prison_episode(today).prison_code
    end

    it 'returns prison code for today' do
      expect(subject).to eq(p3)
    end
  end

  context 'when tomorrow' do
    subject do
      model.prison_episode(tomorrow).prison_code
    end

    it 'returns prison code for tomorrow' do
      expect(subject).to eq(p3)
    end
  end

  context 'when second prison' do
    subject do
      model.prison_episode(two_weeks_ago).prison_code
    end

    it 'returns prison code for last week' do
      expect(subject).to eq(p2)
    end
  end
end
