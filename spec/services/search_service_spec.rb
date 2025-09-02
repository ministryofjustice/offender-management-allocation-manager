require 'rails_helper'

describe SearchService do
  let(:offenders) do
    [
      ["Bob", "Jones", "ABC123"],
      ["Jade", "Smith", "ABC456"],
      ["Grace", "Test", "DEF123"],
      ["John", "Smith", "ABC789"],
      ["David", "Test", "ABC888"],
      ["Alice", "Jones", "ABC999"],
      ['Tester', 'One', 'DEF999']
    ].map do |(first_name, last_name, offender_no)|
      double(first_name:, last_name:, offender_no:)
    end
  end

  def results_for(term) = described_class.search_for_offenders(term, offenders).map(&:offender_no)

  it 'filters by first name' do
    expect(results_for('alice')).to match(['ABC999'])
    expect(results_for('jade')).to match(['ABC456'])
  end

  it 'filters by last name' do
    expect(results_for('smith')).to match(['ABC456', 'ABC789'])
  end

  it 'filters across both first and last names' do
    expect(results_for('test')).to match(['DEF123', 'ABC888', 'DEF999'])
  end

  it 'filters by offender numbers' do
    # full match
    expect(results_for('ABC456')).to match(['ABC456'])
    # partial match
    expect(results_for('ABC')).to match(['ABC123', 'ABC456', 'ABC789', 'ABC888', 'ABC999'])
    expect(results_for('DEF')).to match(['DEF123', 'DEF999'])
    # partial match at end of number
    expect(results_for('123')).to match(['ABC123', 'DEF123'])
  end

  it "will return all of the records if search empty" do
    expect(results_for('').count).to eq(7)
  end

  it "will return no results if search empty" do
    expect(results_for(nil).count).to eq(0)
  end
end
