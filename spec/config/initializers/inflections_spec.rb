require 'rails_helper'

# rubocop:disable RSpec/FilePath
describe ActiveSupport::Inflector do
  describe '#titleize' do
    it 'capitalizes the letter of a string after an apostrophe' do
      expect("BOB O'SHEA".titleize).to eq("Bob O'Shea")
      expect("bob o'shea".titleize).to eq("Bob O'Shea")
      expect("Bob O'Shea".titleize).to eq("Bob O'Shea")
    end

    it 'does not remove a hyphen of a string' do
      expect("Bob Cullen-Smith".titleize).to eq("Bob Cullen-Smith")
      expect("Molly-ann Smith".titleize).to eq("Molly-Ann Smith")
    end
  end
end
# rubocop:enable RSpec/FilePath
