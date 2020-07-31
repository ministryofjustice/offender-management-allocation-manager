FactoryBot.define do
  class Elite2Prison
    attr_accessor :code, :name
  end

  factory :prison, class: 'Elite2Prison' do
    # rotate around every closed prison - open prisons have different rules
    sequence(:code) do |c|
      codes = PrisonService.prison_codes.reject { |x| PrisonService::OPEN_PRISON_CODES.include?(x) }
      codes[c % codes.size]
    end

    name { PrisonService.name_for(code) }
  end
end
