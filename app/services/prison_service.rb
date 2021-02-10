# frozen_string_literal: true

PrisonInfo = Struct.new(:code, :name, :country, :gender)

class PrisonService
  PRISONS = [
    PrisonInfo.new('ACI', 'HMP Altcourse', :england, :male),
    PrisonInfo.new('AGI', 'HMP/YOI Askham Grange', :england, :female),
    PrisonInfo.new('ALI', 'HMP Albany', :england, :male),
    PrisonInfo.new('ASI', 'HMP Ashfield', :england, :male),
    PrisonInfo.new('AYI', 'HMP Aylesbury', :england, :male),
    PrisonInfo.new('BAI', 'HMP Belmarsh', :england, :male),
    PrisonInfo.new('BCI', 'HMP Buckley Hall', :england, :male),
    PrisonInfo.new('BFI', 'HMP Bedford', :england, :male),
    PrisonInfo.new('BHI', 'HMP Blantyre House', :england, :male),
    PrisonInfo.new('BLI', 'HMP Bristol', :england, :male),
    PrisonInfo.new('BMI', 'HMP Birmingham', :england, :male),
    PrisonInfo.new('BNI', 'HMP Bullingdon', :england, :male),
    PrisonInfo.new('BRI', 'HMP Bure', :england, :male),
    PrisonInfo.new('BSI', 'HMP Brinsford', :england, :male),
    PrisonInfo.new('BWI', 'HMP Berwyn', :wales, :male),
    PrisonInfo.new('BXI', 'HMP Brixton', :england, :male),
    PrisonInfo.new('BZI', 'HMP Bronzefield', :england, :female),
    PrisonInfo.new('CDI', 'HMP Chelmsford', :england, :male),
    PrisonInfo.new('CFI', 'HMP Cardiff', :wales, :male),
    PrisonInfo.new('CKI', 'HMP Cookham Wood', :england, :male),
    PrisonInfo.new('CLI', 'HMP Coldingley', :england, :male),
    PrisonInfo.new('CWI', 'HMP Channings Wood', :england, :male),
    PrisonInfo.new('DAI', 'HMP Dartmoor', :england, :male),
    PrisonInfo.new('DGI', 'HMP Dovegate', :england, :male),
    PrisonInfo.new('DHI', 'HMP/YOI Drake Hall', :england, :female),
    PrisonInfo.new('DMI', 'HMP Durham', :england, :male),
    PrisonInfo.new('DNI', 'HMP Doncaster', :england, :male),
    PrisonInfo.new('DTI', 'HMP/YOI Deerbolt', :england, :male),
    PrisonInfo.new('DWI', 'HMP Downview', :england, :female),
    PrisonInfo.new('EEI', 'HMP Erlestoke', :england, :male),
    PrisonInfo.new('EHI', 'HMP Standford Hill', :england, :male),
    PrisonInfo.new('ESI', 'HMP/YOI East Sutton Park', :england, :female),
    PrisonInfo.new('EWI', 'HMP Eastwood Park', :england, :female),
    PrisonInfo.new('EXI', 'HMP Exeter', :england, :male),
    PrisonInfo.new('EYI', 'HMP Elmley', :england, :male),
    PrisonInfo.new('FBI', 'HMP/YOI Forest Bank', :england, :male),
    PrisonInfo.new('FDI', 'HMP Ford', :england, :male),
    PrisonInfo.new('FHI', 'HMP Foston Hall', :england, :female),
    PrisonInfo.new('FKI', 'HMP Frankland', :england, :male),
    PrisonInfo.new('FMI', 'HMP/YOI Feltham', :england, :male),
    PrisonInfo.new('FNI', 'HMP Full Sutton', :england, :male),
    PrisonInfo.new('FSI', 'HMP Featherstone', :england, :male),
    PrisonInfo.new('GHI', 'HMP Garth', :england, :male),
    PrisonInfo.new('GMI', 'HMP Guys Marsh', :england, :male),
    PrisonInfo.new('GNI', 'HMP Grendon', :england, :male),
    PrisonInfo.new('GPI', 'HMP/YOI Glen Parva', :england, :male),
    PrisonInfo.new('GTI', 'HMP Gartree', :england, :male),
    PrisonInfo.new('HBI', 'HMP Hollesley Bay', :england, :male),
    PrisonInfo.new('HCI', 'HMP Huntercombe', :england, :male),
    PrisonInfo.new('HDI', 'HMP/YOI Hatfield', :england, :male),
    PrisonInfo.new('HEI', 'HMP Hewell', :england, :male),
    PrisonInfo.new('HHI', 'HMP Holme House', :england, :male),
    PrisonInfo.new('HII', 'HMP/YOI Hindley', :england, :male),
    PrisonInfo.new('HLI', 'HMP Hull', :england, :male),
    PrisonInfo.new('HMI', 'HMP Humber', :england, :male),
    PrisonInfo.new('HOI', 'HMP High Down', :england, :male),
    PrisonInfo.new('HPI', 'HMP Highpoint', :england, :male),
    PrisonInfo.new('HVI', 'HMP Haverigg', :england, :male),
    PrisonInfo.new('ISI', 'HMP/YOI Isis', :england, :male),
    PrisonInfo.new('IWI', 'HMP Isle Of Wight', :england, :male),
    PrisonInfo.new('KMI', 'HMP Kirkham', :england, :male),
    PrisonInfo.new('KTI', 'HMP Kennet', :england, :male),
    PrisonInfo.new('KVI', 'HMP Kirklevington Grange', :england, :male),
    PrisonInfo.new('LCI', 'HMP Leicester', :england, :male),
    PrisonInfo.new('LEI', 'HMP Leeds', :england, :male),
    PrisonInfo.new('LFI', 'HMP/YOI Lancaster Farms', :england, :male),
    PrisonInfo.new('LGI', 'HMP Lowdham Grange', :england, :male),
    PrisonInfo.new('LHI', 'HMP Lindholme', :england, :male),
    PrisonInfo.new('LII', 'HMP Lincoln', :england, :male),
    PrisonInfo.new('LLI', 'HMP Long Lartin', :england, :male),
    PrisonInfo.new('LNI', 'HMP Low Newton', :england, :female),
    PrisonInfo.new('LPI', 'HMP Liverpool', :england, :male),
    PrisonInfo.new('LTI', 'HMP Littlehey', :england, :male),
    PrisonInfo.new('LWI', 'HMP Lewes', :england, :male),
    PrisonInfo.new('LYI', 'HMP Leyhill', :england, :male),
    PrisonInfo.new('MDI', 'HMP/YOI Moorland', :england, :male),
    PrisonInfo.new('MRI', 'HMP Manchester', :england, :male),
    PrisonInfo.new('MSI', 'HMP Maidstone', :england, :male),
    PrisonInfo.new('MTI', 'HMP The Mount', :england, :male),
    PrisonInfo.new('MWI', 'HMP Medway', :england, :male),
    PrisonInfo.new('NHI', 'HMP New Hall', :england, :female),
    PrisonInfo.new('NLI', 'HMP Northumberland', :england, :male),
    PrisonInfo.new('NMI', 'HMP Nottingham', :england, :male),
    PrisonInfo.new('NSI', 'HMP North Sea Camp', :england, :male),
    PrisonInfo.new('NWI', 'HMP/YOI Norwich', :england, :male),
    PrisonInfo.new('ONI', 'HMP Onley', :england, :male),
    PrisonInfo.new('OWI', 'HMP Oakwood', :england, :male),
    PrisonInfo.new('PBI', 'HMP Peterborough', :england, :male),
    PrisonInfo.new('PFI', 'HMP Peterborough (Female)', :england, :female),
    PrisonInfo.new('PDI', 'HMP/YOI Portland', :england, :male),
    PrisonInfo.new('PNI', 'HMP Preston', :england, :male),
    PrisonInfo.new('PRI', 'HMP Parc', :wales, :male),
    PrisonInfo.new('PVI', 'HMP Pentonville', :england, :male),
    PrisonInfo.new('RCI', 'HMP/YOI Rochester', :england, :male),
    PrisonInfo.new('RHI', 'HMP Rye Hill', :england, :male),
    PrisonInfo.new('RNI', 'HMP Ranby', :england, :male),
    PrisonInfo.new('RSI', 'HMP Risley', :england, :male),
    PrisonInfo.new('SDI', 'HMP Send', :england, :female),
    PrisonInfo.new('SFI', 'HMP Stafford', :england, :male),
    PrisonInfo.new('SHI', 'HMP/YOI Stoke Heath', :england, :male),
    PrisonInfo.new('SKI', 'HMP Stocken', :england, :male),
    PrisonInfo.new('SLI', 'HMP Swaleside', :england, :male),
    PrisonInfo.new('SNI', 'HMP Swinfen Hall', :england, :male),
    PrisonInfo.new('SPI', 'HMP Spring Hill', :england, :male),
    PrisonInfo.new('STI', 'HMP/YOI Styal', :england, :female),
    PrisonInfo.new('SUI', 'HMP/YOI Sudbury', :england, :male),
    PrisonInfo.new('SWI', 'HMP Swansea', :wales, :male),
    PrisonInfo.new('TCI', 'HMP/YOI Thorn Cross', :england, :male),
    PrisonInfo.new('TSI', 'HMP Thameside', :england, :male),
    PrisonInfo.new('UKI', 'HMP Usk', :wales, :male),
    PrisonInfo.new('UPI', 'HMP/YOI Prescoed', :wales, :male),
    PrisonInfo.new('VEI', 'HMP The Verne', :england, :male),
    PrisonInfo.new('WCI', 'HMP Winchester', :england, :male),
    PrisonInfo.new('WDI', 'HMP Wakefield', :england, :male),
    PrisonInfo.new('WEI', 'HMP Wealstun', :england, :male),
    PrisonInfo.new('WHI', 'HMP Woodhill', :england, :male),
    PrisonInfo.new('WII', 'HMP Warren Hill', :england, :male),
    PrisonInfo.new('WLI', 'HMP Wayland', :england, :male),
    PrisonInfo.new('WMI', 'HMP Wymott', :england, :male),
    PrisonInfo.new('WNI', 'HMP/YOI Werrington', :england, :male),
    PrisonInfo.new('WRI', 'HMP Whitemoor', :england, :male),
    PrisonInfo.new('WSI', 'HMP Wormwood Scrubs', :england, :male),
    PrisonInfo.new('WTI', 'HMP Whatton', :england, :male),
    PrisonInfo.new('WWI', 'HMP Wandsworth', :england, :male),
    PrisonInfo.new('WYI', 'HMP/YOI Wetherby', :england, :male)
  ].index_by(&:code).freeze

  PRESCOED_CODE = 'UPI'

  PRIVATE_ENGLISH_PRISON_CODES = %w[ACI ASI DNI DGI FBI LGI OWI NLI PBI RHI TSI].freeze

  ENGLISH_HUB_PRISON_CODES = %w[IWI SLI VEI].freeze

  OPEN_PRISON_CODES = %w[HDI HBI HVI KMI KVI LYI NSI UPI SPI EHI SUI TCI FDI].freeze

  WOMENS_PRISON_CODES = PRISONS.values.select { |p| p.gender == :female }.map(&:code).freeze

  def self.prison_codes
    PRISONS.keys
  end

  def self.english_private_prison?(code)
    PRIVATE_ENGLISH_PRISON_CODES.include?(code)
  end

  def self.english_hub_prison?(code)
    ENGLISH_HUB_PRISON_CODES.include?(code)
  end

  def self.open_prison?(code)
    OPEN_PRISON_CODES.include?(code)
  end

  # This should be the only place that hits the womens_estate flag,
  # as everything should be calling this to decide what to do.
  def self.womens_prison?(code)
    if Flipflop.womens_estate?
      PRISONS[code].gender == :female
    else
      false
    end
  end

  def self.name_for(code)
    PRISONS[code]&.name
  end

  def self.country_for(code)
    PRISONS[code]&.country
  end

  def self.exists?(code)
    PRISONS.key? code
  end

  def self.prisons_from_list(codelist)
    prisons = codelist.index_with { |code| PRISONS[code]&.name }
    prisons.compact.sort_by { |_code, prison| prison }.to_h
  end
end
