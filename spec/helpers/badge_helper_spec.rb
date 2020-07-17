require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the BadgeHelper. For example:
#
# describe BadgeHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe BadgeHelper, type: :helper do
  context 'when determinate' do
    let(:offender) { build(:offender, :determinate) }

    it 'is blue' do
      expect(helper.badge_colour(offender)).to eq 'blue'
    end

    it 'displays determinant' do
      expect(helper.badge_text(offender)).to eq 'Determinate'
    end
  end

  context 'when indeterminate' do
    let(:offender) { build(:offender, :indeterminate) }

    it 'is purple' do
      expect(helper.badge_colour(offender)).to eq 'purple'
    end

    it 'displays indeterminate' do
      expect(helper.badge_text(offender)).to eq 'Indeterminate'
    end
  end
end
