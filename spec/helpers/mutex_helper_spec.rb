require 'rails_helper'

RSpec.describe MutexHelper, type: :helper do
  let(:name) { described_class.class }
  let(:id) { "abc" }

  before do
    helper.create_lock(name, id)
  end

  describe "Create lock" do
    it "Creates lock in cache as expected" do
      expect(Rails.cache.exist? get_lock_key(name, id)).to be(true)
    end

    it "Lock exists returns true" do
      expect(helper.lock_exists(name, id)).to be(true)
    end

    it "Removes existing lock" do
      expect(helper.lock_exists(name, id)).to be(true)
      helper.remove_lock(name, id)
      expect(helper.lock_exists(name, id)).to be(false)
    end
  end
end
