FactoryBot.define do
  CLOSED_PRISON_CODES = PrisonService.prison_codes.reject { |x|
    PrisonService::OPEN_PRISON_CODES.include?(x) ||
      PrisonService::ENGLISH_HUB_PRISON_CODES.include?(x) ||
      PrisonService::WOMENS_PRISON_CODES.include?(x)
  }
  class Elite2Prison
    delegate :code, :name, :womens?, to: :@prison

    def code=(code)
      @prison = Prison.new code
    end
  end

  factory :prison, class: 'Elite2Prison' do
    # rotate around every closed prison - open prisons have different rules
    sequence(:code) do |c|
      CLOSED_PRISON_CODES[c % CLOSED_PRISON_CODES.size]
    end
  end

  factory :womens_prison, parent: :prison do
    sequence(:code) do |c|
      PrisonService::WOMENS_PRISON_CODES[c % PrisonService::WOMENS_PRISON_CODES.size]
    end
  end
end
