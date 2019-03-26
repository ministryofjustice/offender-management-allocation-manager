require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe 'formatting date strings' do
    it "will parse dates into strings" do
      expect(format_date_string('1973-02-21')).to eq('21/02/1973')
    end
  end

  describe 'returns the correct label' do
    it "for service provider CRC" do
      expect(service_provider_label('CRC')).to eq('Community Rehabilitation Company (CRC)')
    end

    it "for service provider NPS" do
      expect(service_provider_label('NPS')).to eq('National Probation Service (NPS)')
    end
  end

  describe 'release or parole date' do
    it "has parole but no release" do
      offender = Nomis::Models::Offender.new.tap { |o|
        o.parole_eligibility_date = Date.new(2019, 1, 1)
      }

      expect(parole_or_release_date(offender)).to eq('01/01/2019')
    end

    it "has release but no parole" do
      offender = Nomis::Models::Offender.new.tap { |o|
        o.release_date = Date.new(2019, 1, 1)
      }

      expect(parole_or_release_date(offender)).to eq('01/01/2019')
    end

    it "has both parole and release" do
      offender = Nomis::Models::Offender.new.tap { |o|
        o.parole_eligibility_date = Date.new(2020, 1, 1)
        o.release_date = Date.new(2021, 1, 1)
      }

      expect(parole_or_release_date(offender)).to eq('01/01/2020')
    end

    it "is indeterminate" do
      offender = Nomis::Models::Offender.new.tap { |o|
        o.has_indeterminate_release_date = true
      }

      expect(parole_or_release_date(offender)).to eq('')
    end
  end
end
