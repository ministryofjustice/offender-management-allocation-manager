# frozen_string_literal: true

PrisonInfo = Struct.new(:code, :name, :country)

class PrisonService
  PRISONS = {
    'ACI' => PrisonInfo.new('ACI', 'HMP Altcourse', :england),
    'AGI' => PrisonInfo.new('AGI', 'HMP/YOI Askham Grange', :england),
    'ALI' => PrisonInfo.new('ALI', 'HMP Albany', :england),
    'ASI' => PrisonInfo.new('ASI', 'HMP Ashfield', :england),
    'AYI' => PrisonInfo.new('AYI', 'HMP Aylesbury', :england),
    'BAI' => PrisonInfo.new('BAI', 'HMP Belmarsh', :england),
    'BCI' => PrisonInfo.new('BCI', 'HMP Buckley Hall', :england),
    'BFI' => PrisonInfo.new('BFI', 'HMP Bedford', :england),
    'BHI' => PrisonInfo.new('BHI', 'HMP Blantyre House', :england),
    'BLI' => PrisonInfo.new('BLI', 'HMP Bristol', :england),
    'BMI' => PrisonInfo.new('BMI', 'HMP Birmingham', :england),
    'BNI' => PrisonInfo.new('BNI', 'HMP Bullingdon', :england),
    'BRI' => PrisonInfo.new('BRI', 'HMP Bure', :england),
    'BSI' => PrisonInfo.new('BSI', 'HMP Brinsford', :england),
    'BWI' => PrisonInfo.new('BWI', 'HMP Berwyn', :wales),
    'BXI' => PrisonInfo.new('BXI', 'HMP Brixton', :england),
    'BZI' => PrisonInfo.new('BZI', 'HMP Bronzefield', :england),
    'CDI' => PrisonInfo.new('CDI', 'HMP Chelmsford', :england),
    'CFI' => PrisonInfo.new('CFI', 'HMP Cardiff', :wales),
    'CKI' => PrisonInfo.new('CKI', 'HMP Cookham Wood', :england),
    'CLI' => PrisonInfo.new('CLI', 'HMP Coldingley', :england),
    'CWI' => PrisonInfo.new('CWI', 'HMP Channings Wood', :england),
    'DAI' => PrisonInfo.new('DAI', 'HMP Dartmoor', :england),
    'DGI' => PrisonInfo.new('DGI', 'HMP Dovegate', :england),
    'DHI' => PrisonInfo.new('DHI', 'HMP/YOI Drake Hall', :england),
    'DMI' => PrisonInfo.new('DMI', 'HMP Durham', :england),
    'DNI' => PrisonInfo.new('DNI', 'HMP Doncaster', :england),
    'DTI' => PrisonInfo.new('DTI', 'HMP/YOI Deerbolt', :england),
    'DWI' => PrisonInfo.new('DWI', 'HMP Downview', :england),
    'EEI' => PrisonInfo.new('EEI', 'HMP Erlestoke', :england),
    'EHI' => PrisonInfo.new('EHI', 'HMP Standford Hill', :england),
    'ESI' => PrisonInfo.new('ESI', 'HMP/YOI East Sutton Park', :england),
    'EWI' => PrisonInfo.new('EWI', 'HMP Eastwood Park', :england),
    'EXI' => PrisonInfo.new('EXI', 'HMP Exeter', :england),
    'EYI' => PrisonInfo.new('EYI', 'HMP Elmley', :england),
    'FBI' => PrisonInfo.new('FBI', 'HMP/YOI Forest Bank', :england),
    'FDI' => PrisonInfo.new('FDI', 'HMP Ford', :england),
    'FHI' => PrisonInfo.new('FHI', 'HMP Foston Hall', :england),
    'FKI' => PrisonInfo.new('FKI', 'HMP Frankland', :england),
    'FMI' => PrisonInfo.new('FMI', 'HMP/YOI Feltham', :england),
    'FNI' => PrisonInfo.new('FNI', 'HMP Full Sutton', :england),
    'FSI' => PrisonInfo.new('FSI', 'HMP Featherstone', :england),
    'GHI' => PrisonInfo.new('GHI', 'HMP Garth', :england),
    'GMI' => PrisonInfo.new('GMI', 'HMP Guys Marsh', :england),
    'GNI' => PrisonInfo.new('GNI', 'HMP Grendon', :england),
    'GPI' => PrisonInfo.new('GPI', 'HMP/YOI Glen Parva', :england),
    'GTI' => PrisonInfo.new('GTI', 'HMP Gartree', :england),
    'HBI' => PrisonInfo.new('HBI', 'HMP Hollesley Bay', :england),
    'HCI' => PrisonInfo.new('HCI', 'HMP Huntercombe', :england),
    'HDI' => PrisonInfo.new('HDI', 'HMP/YOI Hatfield', :england),
    'HEI' => PrisonInfo.new('HEI', 'HMP Hewell', :england),
    'HHI' => PrisonInfo.new('HHI', 'HMP Holme House', :england),
    'HII' => PrisonInfo.new('HII', 'HMP/YOI Hindley', :england),
    'HLI' => PrisonInfo.new('HLI', 'HMP Hull', :england),
    'HMI' => PrisonInfo.new('HMI', 'HMP Humber', :england),
    'HOI' => PrisonInfo.new('HOI', 'HMP High Down', :england),
    'HPI' => PrisonInfo.new('HPI', 'HMP Highpoint', :england),
    'HVI' => PrisonInfo.new('HVI', 'HMP Haverigg', :england),
    'ISI' => PrisonInfo.new('ISI', 'HMP/YOI Isis', :england),
    'IWI' => PrisonInfo.new('IWI', 'HMP Isle Of Wight', :england),
    'KMI' => PrisonInfo.new('KMI', 'HMP Kirkham', :england),
    'KTI' => PrisonInfo.new('KTI', 'HMP Kennet', :england),
    'KVI' => PrisonInfo.new('KVI', 'HMP Kirklevington Grange', :england),
    'LCI' => PrisonInfo.new('LCI', 'HMP Leicester', :england),
    'LEI' => PrisonInfo.new('LEI', 'HMP Leeds', :england),
    'LFI' => PrisonInfo.new('LFI', 'HMP/YOI Lancaster Farms', :england),
    'LGI' => PrisonInfo.new('LGI', 'HMP Lowdham Grange', :england),
    'LHI' => PrisonInfo.new('LHI', 'HMP Lindholme', :england),
    'LII' => PrisonInfo.new('LII', 'HMP Lincoln', :england),
    'LLI' => PrisonInfo.new('LLI', 'HMP Long Lartin', :england),
    'LNI' => PrisonInfo.new('LNI', 'HMP Low Newton', :england),
    'LPI' => PrisonInfo.new('LPI', 'HMP Liverpool', :england),
    'LTI' => PrisonInfo.new('LTI', 'HMP Littlehey', :england),
    'LWI' => PrisonInfo.new('LWI', 'HMP Lewes', :england),
    'LYI' => PrisonInfo.new('LYI', 'HMP Leyhill', :england),
    'MDI' => PrisonInfo.new('MDI', 'HMP/YOI Moorland', :england),
    'MRI' => PrisonInfo.new('MRI', 'HMP Manchester', :england),
    'MSI' => PrisonInfo.new('MSI', 'HMP Maidstone', :england),
    'MTI' => PrisonInfo.new('MTI', 'HMP The Mount', :england),
    'MWI' => PrisonInfo.new('MWI', 'HMP Medway', :england),
    'NHI' => PrisonInfo.new('NHI', 'HMP New Hall', :england),
    'NLI' => PrisonInfo.new('NLI', 'HMP Northumberland', :england),
    'NMI' => PrisonInfo.new('NMI', 'HMP Nottingham', :england),
    'NSI' => PrisonInfo.new('NSI', 'HMP North Sea Camp', :england),
    'NWI' => PrisonInfo.new('NWI', 'HMP/YOI Norwich', :england),
    'ONI' => PrisonInfo.new('ONI', 'HMP Onley', :england),
    'OWI' => PrisonInfo.new('OWI', 'HMP Oakwood', :england),
    'PBI' => PrisonInfo.new('PBI', 'HMP Peterborough', :england),
    'PDI' => PrisonInfo.new('PDI', 'HMP/YOI Portland', :england),
    'PNI' => PrisonInfo.new('PNI', 'HMP Preston', :england),
    'PRI' => PrisonInfo.new('PRI', 'HMP Parc', :wales),
    'PVI' => PrisonInfo.new('PVI', 'HMP Pentonville', :england),
    'RCI' => PrisonInfo.new('RCI', 'HMP/YOI Rochester', :england),
    'RHI' => PrisonInfo.new('RHI', 'HMP Rye Hill', :england),
    'RNI' => PrisonInfo.new('RNI', 'HMP Ranby', :england),
    'RSI' => PrisonInfo.new('RSI', 'HMP Risley', :england),
    'SDI' => PrisonInfo.new('SDI', 'HMP Send', :england),
    'SFI' => PrisonInfo.new('SFI', 'HMP Stafford', :england),
    'SHI' => PrisonInfo.new('SHI', 'HMP/YOI Stoke Heath', :england),
    'SKI' => PrisonInfo.new('SKI', 'HMP Stocken', :england),
    'SLI' => PrisonInfo.new('SLI', 'HMP Swaleside', :england),
    'SNI' => PrisonInfo.new('SNI', 'HMP Swinfen Hall', :england),
    'SPI' => PrisonInfo.new('SPI', 'HMP Spring Hill', :england),
    'STI' => PrisonInfo.new('STI', 'HMP/YOI Styal', :england),
    'SUI' => PrisonInfo.new('SUI', 'HMP/YOI Sudbury', :england),
    'SWI' => PrisonInfo.new('SWI', 'HMP Swansea', :wales),
    'TCI' => PrisonInfo.new('TCI', 'HMP/YOI Thorn Cross', :england),
    'TSI' => PrisonInfo.new('TSI', 'HMP Thameside', :england),
    'UKI' => PrisonInfo.new('UKI', 'HMP Usk', :wales),
    'UPI' => PrisonInfo.new('UPI', 'HMP/YOI Prescoed', :wales),
    'VEI' => PrisonInfo.new('VEI', 'HMP The Verne', :england),
    'WCI' => PrisonInfo.new('WCI', 'HMP Winchester', :england),
    'WDI' => PrisonInfo.new('WDI', 'HMP Wakefield', :england),
    'WEI' => PrisonInfo.new('WEI', 'HMP Wealstun', :england),
    'WHI' => PrisonInfo.new('WHI', 'HMP Woodhill', :england),
    'WII' => PrisonInfo.new('WII', 'HMP Warren Hill', :england),
    'WLI' => PrisonInfo.new('WLI', 'HMP Wayland', :england),
    'WMI' => PrisonInfo.new('WMI', 'HMP Wymott', :england),
    'WNI' => PrisonInfo.new('WNI', 'HMP/YOI Werrington', :england),
    'WRI' => PrisonInfo.new('WRI', 'HMP Whitemoor', :england),
    'WSI' => PrisonInfo.new('WSI', 'HMP Wormwood Scrubs', :england),
    'WTI' => PrisonInfo.new('WTI', 'HMP Whatton', :england),
    'WWI' => PrisonInfo.new('WWI', 'HMP Wandsworth', :england),
    'WYI' => PrisonInfo.new('WYI', 'HMP/YOI Wetherby', :england)
  }

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
