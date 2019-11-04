require 'rails_helper'

describe Bucket do
  it "can retrieve last n" do
    b = described_class.new(nil)
    (1..5).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
    expect(b.count).to eq(5)
  end

  it "can try to retrieve last n if we request too many" do
    b = described_class.new(nil)
    (1..5).each do |num|
      b << num
    end
    expect(b.items.count).to be(5)
    expect(b.items).to eq([1, 2, 3, 4, 5])
  end

  it "can try to retrieve last n if we have an empty bucket" do
    b = described_class.new(nil)
    expect(b.items.count).to be(0)
    expect(b.items).to eq([])
  end

  it "can sort its items by default ASC" do
    b = described_class.new(nil)
    b << OpenStruct.new(last_name: "Z")
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    expect(b.items.count).to be(3)

    b.sort(:last_name)
    expect(b.items[0].last_name).to eq('A')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('Z')
  end

  it "can sort its items DESC" do
    b = described_class.new(nil)
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    b << OpenStruct.new(last_name: "Z")
    expect(b.items.count).to be(3)

    b.sort(:last_name, :desc)
    expect(b.items[0].last_name).to eq('Z')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('A')
  end

  it "can't sort by made up field, using defaults" do
    b = described_class.new(nil)
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    b << OpenStruct.new(last_name: "Z")
    expect(b.items.count).to be(3)

    b.sort(:test, :desc)
    expect(b.items[0].last_name).to eq('A')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('Z')
  end

  it "when told can't sort by made up field" do
    b = described_class.new([:last_name])
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    b << OpenStruct.new(last_name: "Z")
    expect(b.items.count).to be(3)

    b.sort(:test, :desc)
    expect(b.items[0].last_name).to eq('A')
    expect(b.items[1].last_name).to eq('M')
    expect(b.items[2].last_name).to eq('Z')
  end

  it 'can sort dates containing nulls' do
    b = described_class.new(nil)
    b << OpenStruct.new(
      last_name: "A",
      earliest_release_date: nil
    )
    b << OpenStruct.new(
      last_name: "A",
      earliest_release_date: Date.new(2000, 1, 1)
    )
    b.sort(:earliest_release_date)
    items = b.items[0..1]
    expect(items.count).to eq(2)
    expect(items.first.earliest_release_date).to be_nil
    expect(items[1].earliest_release_date).not_to be_nil

    b.sort(:earliest_release_date, :desc)
    items = b.items[0..1]
    expect(items.count).to eq(2)
    expect(items.first.earliest_release_date).not_to be_nil
    expect(items[1].earliest_release_date).to be_nil
  end
end
