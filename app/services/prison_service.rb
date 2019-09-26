# frozen_string_literal: true

PrisonInfo = Struct.new(:code, :name, :country)

class PrisonService
  PRISONS = [
    PrisonInfo.new('ACI', 'HMP Altcourse', :england),
    PrisonInfo.new('AGI', 'HMP/YOI Askham Grange', :england),
    PrisonInfo.new('ALI', 'HMP Albany', :england),
    PrisonInfo.new('ASI', 'HMP Ashfield', :england),
    PrisonInfo.new('AYI', 'HMP Aylesbury', :england),
    PrisonInfo.new('BAI', 'HMP Belmarsh', :england),
    PrisonInfo.new('BCI', 'HMP Buckley Hall', :england),
    PrisonInfo.new('BFI', 'HMP Bedford', :england),
    PrisonInfo.new('BHI', 'HMP Blantyre House', :england),
    PrisonInfo.new('BLI', 'HMP Bristol', :england),
    PrisonInfo.new('BMI', 'HMP Birmingham', :england),
    PrisonInfo.new('BNI', 'HMP Bullingdon', :england),
    PrisonInfo.new('BRI', 'HMP Bure', :england),
    PrisonInfo.new('BSI', 'HMP Brinsford', :england),
    PrisonInfo.new('BWI', 'HMP Berwyn', :wales),
    PrisonInfo.new('BXI', 'HMP Brixton', :england),
    PrisonInfo.new('BZI', 'HMP Bronzefield', :england),
    PrisonInfo.new('CDI', 'HMP Chelmsford', :england),
    PrisonInfo.new('CFI', 'HMP Cardiff', :wales),
    PrisonInfo.new('CKI', 'HMP Cookham Wood', :england),
    PrisonInfo.new('CLI', 'HMP Coldingley', :england),
    PrisonInfo.new('CWI', 'HMP Channings Wood', :england),
    PrisonInfo.new('DAI', 'HMP Dartmoor', :england),
    PrisonInfo.new('DGI', 'HMP Dovegate', :england),
    PrisonInfo.new('DHI', 'HMP/YOI Drake Hall', :england),
    PrisonInfo.new('DMI', 'HMP Durham', :england),
    PrisonInfo.new('DNI', 'HMP Doncaster', :england),
    PrisonInfo.new('DTI', 'HMP/YOI Deerbolt', :england),
    PrisonInfo.new('DWI', 'HMP Downview', :england),
    PrisonInfo.new('EEI', 'HMP Erlestoke', :england),
    PrisonInfo.new('EHI', 'HMP Standford Hill', :england),
    PrisonInfo.new('ESI', 'HMP/YOI East Sutton Park', :england),
    PrisonInfo.new('EWI', 'HMP Eastwood Park', :england),
    PrisonInfo.new('EXI', 'HMP Exeter', :england),
    PrisonInfo.new('EYI', 'HMP Elmley', :england),
    PrisonInfo.new('FBI', 'HMP/YOI Forest Bank', :england),
    PrisonInfo.new('FDI', 'HMP Ford', :england),
    PrisonInfo.new('FHI', 'HMP Foston Hall', :england),
    PrisonInfo.new('FKI', 'HMP Frankland', :england),
    PrisonInfo.new('FMI', 'HMP/YOI Feltham', :england),
    PrisonInfo.new('FNI', 'HMP Full Sutton', :england),
    PrisonInfo.new('FSI', 'HMP Featherstone', :england),
    PrisonInfo.new('GHI', 'HMP Garth', :england),
    PrisonInfo.new('GMI', 'HMP Guys Marsh', :england),
    PrisonInfo.new('GNI', 'HMP Grendon', :england),
    PrisonInfo.new('GPI', 'HMP/YOI Glen Parva', :england),
    PrisonInfo.new('GTI', 'HMP Gartree', :england),
    PrisonInfo.new('HBI', 'HMP Hollesley Bay', :england),
    PrisonInfo.new('HCI', 'HMP Huntercombe', :england),
    PrisonInfo.new('HDI', 'HMP/YOI Hatfield', :england),
    PrisonInfo.new('HEI', 'HMP Hewell', :england),
    PrisonInfo.new('HHI', 'HMP Holme House', :england),
    PrisonInfo.new('HII', 'HMP/YOI Hindley', :england),
    PrisonInfo.new('HLI', 'HMP Hull', :england),
    PrisonInfo.new('HMI', 'HMP Humber', :england),
    PrisonInfo.new('HOI', 'HMP High Down', :england),
    PrisonInfo.new('HPI', 'HMP Highpoint', :england),
    PrisonInfo.new('HVI', 'HMP Haverigg', :england),
    PrisonInfo.new('ISI', 'HMP/YOI Isis', :england),
    PrisonInfo.new('IWI', 'HMP Isle Of Wight', :england),
    PrisonInfo.new('KMI', 'HMP Kirkham', :england),
    PrisonInfo.new('KTI', 'HMP Kennet', :england),
    PrisonInfo.new('KVI', 'HMP Kirklevington Grange', :england),
    PrisonInfo.new('LCI', 'HMP Leicester', :england),
    PrisonInfo.new('LEI', 'HMP Leeds', :england),
    PrisonInfo.new('LFI', 'HMP/YOI Lancaster Farms', :england),
    PrisonInfo.new('LGI', 'HMP Lowdham Grange', :england),
    PrisonInfo.new('LHI', 'HMP Lindholme', :england),
    PrisonInfo.new('LII', 'HMP Lincoln', :england),
    PrisonInfo.new('LLI', 'HMP Long Lartin', :england),
    PrisonInfo.new('LNI', 'HMP Low Newton', :england),
    PrisonInfo.new('LPI', 'HMP Liverpool', :england),
    PrisonInfo.new('LTI', 'HMP Littlehey', :england),
    PrisonInfo.new('LWI', 'HMP Lewes', :england),
    PrisonInfo.new('LYI', 'HMP Leyhill', :england),
    PrisonInfo.new('MDI', 'HMP/YOI Moorland', :england),
    PrisonInfo.new('MRI', 'HMP Manchester', :england),
    PrisonInfo.new('MSI', 'HMP Maidstone', :england),
    PrisonInfo.new('MTI', 'HMP The Mount', :england),
    PrisonInfo.new('MWI', 'HMP Medway', :england),
    PrisonInfo.new('NHI', 'HMP New Hall', :england),
    PrisonInfo.new('NLI', 'HMP Northumberland', :england),
    PrisonInfo.new('NMI', 'HMP Nottingham', :england),
    PrisonInfo.new('NSI', 'HMP North Sea Camp', :england),
    PrisonInfo.new('NWI', 'HMP/YOI Norwich', :england),
    PrisonInfo.new('ONI', 'HMP Onley', :england),
    PrisonInfo.new('OWI', 'HMP Oakwood', :england),
    PrisonInfo.new('PBI', 'HMP Peterborough', :england),
    PrisonInfo.new('PDI', 'HMP/YOI Portland', :england),
    PrisonInfo.new('PNI', 'HMP Preston', :england),
    PrisonInfo.new('PRI', 'HMP Parc', :wales),
    PrisonInfo.new('PVI', 'HMP Pentonville', :england),
    PrisonInfo.new('RCI', 'HMP/YOI Rochester', :england),
    PrisonInfo.new('RHI', 'HMP Rye Hill', :england),
    PrisonInfo.new('RNI', 'HMP Ranby', :england),
    PrisonInfo.new('RSI', 'HMP Risley', :england),
    PrisonInfo.new('SDI', 'HMP Send', :england),
    PrisonInfo.new('SFI', 'HMP Stafford', :england),
    PrisonInfo.new('SHI', 'HMP/YOI Stoke Heath', :england),
    PrisonInfo.new('SKI', 'HMP Stocken', :england),
    PrisonInfo.new('SLI', 'HMP Swaleside', :england),
    PrisonInfo.new('SNI', 'HMP Swinfen Hall', :england),
    PrisonInfo.new('SPI', 'HMP Spring Hill', :england),
    PrisonInfo.new('STI', 'HMP/YOI Styal', :england),
    PrisonInfo.new('SUI', 'HMP/YOI Sudbury', :england),
    PrisonInfo.new('SWI', 'HMP Swansea', :wales),
    PrisonInfo.new('TCI', 'HMP/YOI Thorn Cross', :england),
    PrisonInfo.new('TSI', 'HMP Thameside', :england),
    PrisonInfo.new('UKI', 'HMP Usk', :wales),
    PrisonInfo.new('UPI', 'HMP/YOI Prescoed', :wales),
    PrisonInfo.new('VEI', 'HMP The Verne', :england),
    PrisonInfo.new('WCI', 'HMP Winchester', :england),
    PrisonInfo.new('WDI', 'HMP Wakefield', :england),
    PrisonInfo.new('WEI', 'HMP Wealstun', :england),
    PrisonInfo.new('WHI', 'HMP Woodhill', :england),
    PrisonInfo.new('WII', 'HMP Warren Hill', :england),
    PrisonInfo.new('WLI', 'HMP Wayland', :england),
    PrisonInfo.new('WMI', 'HMP Wymott', :england),
    PrisonInfo.new('WNI', 'HMP/YOI Werrington', :england),
    PrisonInfo.new('WRI', 'HMP Whitemoor', :england),
    PrisonInfo.new('WSI', 'HMP Wormwood Scrubs', :england),
    PrisonInfo.new('WTI', 'HMP Whatton', :england),
    PrisonInfo.new('WWI', 'HMP Wandsworth', :england),
    PrisonInfo.new('WYI', 'HMP/YOI Wetherby', :england)
  ].map { |p| [p.code, p] }.to_h

  PRIVATE_ENGLISH_PRISON_CODES = %w[ACI ASI DNI DGI FBI LGI OWI NLI PBI RHI TSI]

  ENGLISH_HUB_PRISON_CODES = %w[IWI SLI VEI]

  def self.prison_codes
    PRISONS.keys
  end

  def self.english_private_prison?(code)
    PRIVATE_ENGLISH_PRISON_CODES.include?(code)
  end

  def self.english_hub_prison?(code)
    ENGLISH_HUB_PRISON_CODES.include?(code)
  end

  def self.name_for(code)
    PRISONS[code]&.name
  end

  def self.country_for(code)
    PRISONS[code]&.country
  end

  def self.prisons_from_list(codelist)
    prisons = codelist.each_with_object({}) { |code, hash|
      hash[code] = PRISONS[code]&.name
    }
    prisons.compact.sort_by { |_code, prison| prison }.to_h
  end
end
