require 'rails_helper'

RSpec.describe Responsibility, type: :model do
  context 'with other reason' do
    subject { build(:responsibility, reason: :other_reason) }

    it { is_expected.not_to be_valid }
  end

  context 'with default factory' do
    subject { build(:responsibility) }

    it { is_expected.to be_valid }
  end

  context 'with invalid override' do
    subject { build(:responsibility, value: 'wibble') }

    it { is_expected.not_to be_valid }
  end

  context 'with prison override' do
    subject { build(:responsibility, value: 'Prison') }

    it { is_expected.to be_valid }
  end
end
