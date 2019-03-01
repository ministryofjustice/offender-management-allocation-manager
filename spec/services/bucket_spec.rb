require 'rails_helper'

describe Bucket do
  it "can retrieve last n" do
    b = described_class.new
    (1..5).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
    expect(b.take(3, 2)).to eq([3, 4, 5])
  end

  it "can try to retrieve last n if we request too many" do
    b = described_class.new
    (1..5).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
    expect(b.take(6, 0)).to eq([1, 2, 3, 4, 5])
  end

  it "can try to retrieve last n if we have an empty bucket" do
    b = described_class.new
    expect(b.items.count).to be(0)
    expect(b.items).to eq([])
    expect(b.take(6, 0)).to eq([])
  end

  it "can sort its items by default ASC" do
    b = described_class.new
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "Z" }
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "A" }
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "M" }
    expect(b.items.count).to be(3)

    b.sort(:last_name)
    expect(b.items[0].last_name).to eq('A')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('Z')
  end

  it "can sort its items DESC" do
    b = described_class.new
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "A" }
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "M" }
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "Z" }
    expect(b.items.count).to be(3)

    b.sort(:last_name, :desc)
    expect(b.items[0].last_name).to eq('Z')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('A')
  end

  it "can't sort by made up field" do
    b = described_class.new
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "A" }
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "M" }
    b << Nomis::Models::OffenderShort.new.tap { |o| o.last_name = "Z" }
    expect(b.items.count).to be(3)

    b.sort(:test, :desc)
    expect(b.items[0].last_name).to eq('A')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('Z')
  end
end
