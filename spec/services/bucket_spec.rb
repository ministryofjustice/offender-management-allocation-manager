require 'rails_helper'

describe Bucket do
  it "will complain if capacity is too low" do
    expect { described_class.new(0) }.to raise_error(BucketCapacityException)
    expect { described_class.new(-1) }.to raise_error(BucketCapacityException)
  end

  it "will overflow if full" do
    b = described_class.new(5)
    (1..10).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
  end

  it "can retrieve last n" do
    b = described_class.new(5)
    (1..10).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
    expect(b.last(3)).to eq([3, 4, 5])
  end

  it "can try to retrieve last n if we request too many" do
    b = described_class.new(5)
    (1..5).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
    expect(b.last(6)).to eq([1, 2, 3, 4, 5])
  end

  it "can try to retrieve last n if we have an empty bucket" do
    b = described_class.new(5)
    expect(b.items.count).to be(0)
    expect(b.items).to eq([])
    expect(b.last(6)).to eq([])
  end

  it "will correctly determine when it is full" do
    b = described_class.new(1)

    expect(b.full?).to be false
    b << 1
    expect(b.full?).to be true
  end
end
