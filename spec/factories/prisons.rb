FactoryBot.define do
  CLOSED_PRISON_CODES = PrisonService.prison_codes.reject { |x|
    PrisonService::OPEN_PRISON_CODES.include?(x) || PrisonService::ENGLISH_HUB_PRISON_CODES.include?(x)
  }
  class Elite2Prison
    attr_accessor :code, :name
  end

  factory :prison, class: 'Elite2Prison' do
    # rotate around every closed prison - open prisons have different rules
    sequence(:code) do |c|
      CLOSED_PRISON_CODES[c % CLOSED_PRISON_CODES.size]
    end

    name { PrisonService.name_for(code) }
  end
end
