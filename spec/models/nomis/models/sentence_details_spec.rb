require 'rails_helper'

describe Nomis::Models::SentenceDetail, model: true do
  it 'can work out indeterminate release dates' do
    sentence_data = described_class.new.tap { |details|
      details.sentence_detail = {
        'tariff_date' => '2020-01-01'
      }
    }
    expect(sentence_data.indeterminate_release_date?).to be true
  end
end
