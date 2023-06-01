# frozen_string_literal: true

PrisonInfo = Struct.new(:code, :name, :country, :gender)

class PrisonService
  PRISONS = [
    PrisonInfo.new('ACI', 'Altcourse (HMP)', :england, :male),
    PrisonInfo.new('AGI', 'Askham Grange (HMP/YOI)', :england, :female),
    PrisonInfo.new('ASI', 'Ashfield (HMP)', :england, :male),
    PrisonInfo.new('AYI', 'Aylesbury (HMP)', :england, :male),
    PrisonInfo.new('BAI', 'Belmarsh (HMP)', :england, :male),
    PrisonInfo.new('BCI', 'Buckley Hall (HMP)', :england, :male),
    PrisonInfo.new('BFI', 'Bedford (HMP)', :england, :male),
    PrisonInfo.new('BLI', 'Bristol (HMP)', :england, :male),
    PrisonInfo.new('BMI', 'Birmingham (HMP)', :england, :male),
    PrisonInfo.new('BNI', 'Bullingdon (HMP)', :england, :male),
    PrisonInfo.new('BRI', 'Bure (HMP)', :england, :male),
    PrisonInfo.new('BSI', 'Brinsford (HMP)', :england, :male),
    PrisonInfo.new('BWI', 'Berwyn (HMP)', :wales, :male),
    PrisonInfo.new('BXI', 'Brixton (HMP)', :england, :male),
    PrisonInfo.new('BZI', 'Bronzefield (HMP)', :england, :female),
    PrisonInfo.new('CDI', 'Chelmsford (HMP)', :england, :male),
    PrisonInfo.new('CFI', 'Cardiff (HMP)', :wales, :male),
    PrisonInfo.new('CKI', 'Cookham Wood (HMP)', :england, :male),
    PrisonInfo.new('CLI', 'Coldingley (HMP)', :england, :male),
    PrisonInfo.new('CWI', 'Channings Wood (HMP)', :england, :male),
    PrisonInfo.new('DAI', 'Dartmoor (HMP)', :england, :male),
    PrisonInfo.new('DGI', 'Dovegate (HMP)', :england, :male),
    PrisonInfo.new('DHI', 'Drake Hall (HMP/YOI)', :england, :female),
    PrisonInfo.new('DMI', 'Durham (HMP)', :england, :male),
    PrisonInfo.new('DNI', 'Doncaster (HMP)', :england, :male),
    PrisonInfo.new('DTI', 'Deerbolt (HMP/YOI)', :england, :male),
    PrisonInfo.new('DWI', 'Downview (HMP)', :england, :female),
    PrisonInfo.new('EEI', 'Erlestoke (HMP)', :england, :male),
    PrisonInfo.new('EHI', 'Standford Hill (HMP)', :england, :male),
    PrisonInfo.new('ESI', 'East Sutton Park (HMP/YOI)', :england, :female),
    PrisonInfo.new('EWI', 'Eastwood Park (HMP)', :england, :female),
    PrisonInfo.new('EXI', 'Exeter (HMP)', :england, :male),
    PrisonInfo.new('EYI', 'Elmley (HMP)', :england, :male),
    PrisonInfo.new('FBI', 'Forest Bank (HMP/YOI)', :england, :male),
    PrisonInfo.new('FDI', 'Ford (HMP)', :england, :male),
    PrisonInfo.new('FEI', 'Fosse Way (HMP/YOI)', :england, :male),
    PrisonInfo.new('FHI', 'Foston Hall (HMP)', :england, :female),
    PrisonInfo.new('FKI', 'Frankland (HMP)', :england, :male),
    PrisonInfo.new('FMI', 'Feltham (HMP/YOI)', :england, :male),
    PrisonInfo.new('FNI', 'Full Sutton (HMP)', :england, :male),
    PrisonInfo.new('FSI', 'Featherstone (HMP)', :england, :male),
    PrisonInfo.new('FWI', 'Five Wells (FWI)', :england, :male),
    PrisonInfo.new('GHI', 'Garth (HMP)', :england, :male),
    PrisonInfo.new('GMI', 'Guys Marsh (HMP)', :england, :male),
    PrisonInfo.new('GNI', 'Grendon (HMP)', :england, :male),
    PrisonInfo.new('GTI', 'Gartree (HMP)', :england, :male),
    PrisonInfo.new('HBI', 'Hollesley Bay (HMP)', :england, :male),
    PrisonInfo.new('HCI', 'Huntercombe (HMP)', :england, :male),
    PrisonInfo.new('HDI', 'Hatfield (HMP/YOI)', :england, :male),
    PrisonInfo.new('HEI', 'Hewell (HMP)', :england, :male),
    PrisonInfo.new('HHI', 'Holme House (HMP)', :england, :male),
    PrisonInfo.new('HII', 'Hindley (HMP/YOI)', :england, :male),
    PrisonInfo.new('HLI', 'Hull (HMP)', :england, :male),
    PrisonInfo.new('HMI', 'Humber (HMP)', :england, :male),
    PrisonInfo.new('HOI', 'High Down (HMP)', :england, :male),
    PrisonInfo.new('HPI', 'Highpoint (HMP)', :england, :male),
    PrisonInfo.new('HVI', 'Haverigg (HMP)', :england, :male),
    PrisonInfo.new('ISI', 'Isis (HMP/YOI)', :england, :male),
    PrisonInfo.new('IWI', 'Isle Of Wight (HMP)', :england, :male),
    PrisonInfo.new('KMI', 'Kirkham (HMP)', :england, :male),
    PrisonInfo.new('KVI', 'Kirklevington Grange (HMP)', :england, :male),
    PrisonInfo.new('LCI', 'Leicester (HMP)', :england, :male),
    PrisonInfo.new('LEI', 'Leeds (HMP)', :england, :male),
    PrisonInfo.new('LFI', 'Lancaster Farms (HMP/YOI)', :england, :male),
    PrisonInfo.new('LGI', 'Lowdham Grange (HMP)', :england, :male),
    PrisonInfo.new('LHI', 'Lindholme (HMP)', :england, :male),
    PrisonInfo.new('LII', 'Lincoln (HMP)', :england, :male),
    PrisonInfo.new('LLI', 'Long Lartin (HMP)', :england, :male),
    PrisonInfo.new('LNI', 'Low Newton(HMP)', :england, :female),
    PrisonInfo.new('LPI', 'Liverpool (HMP)', :england, :male),
    PrisonInfo.new('LTI', 'Littlehey (HMP)', :england, :male),
    PrisonInfo.new('LWI', 'Lewes (HMP)', :england, :male),
    PrisonInfo.new('LYI', 'Leyhill (HMP)', :england, :male),
    PrisonInfo.new('MDI', 'Moorland (HMP/YOI)', :england, :male),
    PrisonInfo.new('MHI', 'Morton Hall (HMP)', :england, :male),
    PrisonInfo.new('MRI', 'Manchester (HMP)', :england, :male),
    PrisonInfo.new('MSI', 'Maidstone (HMP)', :england, :male),
    PrisonInfo.new('MTI', 'The Mount (HMP)', :england, :male),
    PrisonInfo.new('NHI', 'New Hall (HMP)', :england, :female),
    PrisonInfo.new('NLI', 'Northumberland (HMP)', :england, :male),
    PrisonInfo.new('NMI', 'Nottingham (HMP)', :england, :male),
    PrisonInfo.new('NSI', 'North Sea Camp (HMP)', :england, :male),
    PrisonInfo.new('NWI', 'Norwich (HMP/YOI)', :england, :male),
    PrisonInfo.new('ONI', 'Onley (HMP)', :england, :male),
    PrisonInfo.new('OWI', 'Oakwood (HMP)', :england, :male),
    PrisonInfo.new('PBI', 'Peterborough (HMP)', :england, :male),
    PrisonInfo.new('PDI', 'Portland (HMP/YOI)', :england, :male),
    PrisonInfo.new('PFI', 'Peterborough Female (HMP)', :england, :female),
    PrisonInfo.new('PNI', 'Preston (HMP)', :england, :male),
    PrisonInfo.new('PRI', 'Parc (HMP)', :wales, :male),
    PrisonInfo.new('PVI', 'Pentonville (HMP)', :england, :male),
    PrisonInfo.new('RCI', 'Rochester (HMP/YOI)', :england, :male),
    PrisonInfo.new('RHI', 'Rye Hill (HMP)', :england, :male),
    PrisonInfo.new('RNI', 'Ranby (HMP)', :england, :male),
    PrisonInfo.new('RSI', 'Risley (HMP)', :england, :male),
    PrisonInfo.new('SDI', 'Send (HMP)', :england, :female),
    PrisonInfo.new('SFI', 'Stafford (HMP)', :england, :male),
    PrisonInfo.new('SHI', 'Stoke Heath (HMP/YOI)', :england, :male),
    PrisonInfo.new('SKI', 'Stocken (HMP)', :england, :male),
    PrisonInfo.new('SLI', 'Swaleside (HMP)', :england, :male),
    PrisonInfo.new('SNI', 'Swinfen Hall (HMP)', :england, :male),
    PrisonInfo.new('SPI', 'Spring Hill (HMP)', :england, :male),
    PrisonInfo.new('STI', 'Styal (HMP/YOI)', :england, :female),
    PrisonInfo.new('SUI', 'Sudbury (HMP/YOI)', :england, :male),
    PrisonInfo.new('SWI', 'Swansea (HMP)', :wales, :male),
    PrisonInfo.new('TCI', 'Thorn Cross (HMP/YOI)', :england, :male),
    PrisonInfo.new('TSI', 'Thameside (HMP)', :england, :male),
    PrisonInfo.new('UKI', 'Usk (HMP)', :wales, :male),
    PrisonInfo.new('UPI', 'Prescoed (HMP/YOI)', :wales, :male),
    PrisonInfo.new('VEI', 'The Verne (HMP)', :england, :male),
    PrisonInfo.new('WCI', 'Winchester (HMP)', :england, :male),
    PrisonInfo.new('WDI', 'Wakefield (HMP)', :england, :male),
    PrisonInfo.new('WEI', 'Wealstun (HMP)', :england, :male),
    PrisonInfo.new('WHI', 'Woodhill (HMP)', :england, :male),
    PrisonInfo.new('WII', 'Warren Hill (HMP)', :england, :male),
    PrisonInfo.new('WLI', 'Wayland (HMP)', :england, :male),
    PrisonInfo.new('WMI', 'Wymott (HMP)', :england, :male),
    PrisonInfo.new('WNI', 'Werrington (HMP/YOI)', :england, :male),
    PrisonInfo.new('WRI', 'Whitemoor (HMP)', :england, :male),
    PrisonInfo.new('WSI', 'Wormwood Scrubs (HMP)', :england, :male),
    PrisonInfo.new('WTI', 'Whatton (HMP)', :england, :male),
    PrisonInfo.new('WWI', 'Wandsworth (HMP)', :england, :male),
    PrisonInfo.new('WYI', 'Wetherby (HMP/YOI)', :england, :male)
  ].index_by(&:code).freeze

  # Coverage is not used in real code only used in rake task import:prison
  # :nocov:
  def self.prison_type(prison)
    if prison.gender == :male
      if OPEN_PRISON_CODES.include?(prison.code)
        'mens_open'
      else
        'mens_closed'
      end
    else
      'womens'
    end
  end
  # :nocov:

  PRESCOED_CODE = 'UPI'

  PRIVATE_ENGLISH_PRISON_CODES = %w[ACI ASI DNI DGI FBI LGI OWI NLI PBI RHI TSI].freeze

  ENGLISH_HUB_PRISON_CODES = %w[IWI SLI VEI].freeze

  OPEN_PRISON_CODES = %w[HDI HBI HVI KMI KVI LYI NSI UPI SPI EHI SUI TCI FDI].freeze

  WOMENS_PRISON_CODES = PRISONS.values.select { |p| p.gender == :female }.map(&:code).freeze

  # This method is needed for email history.
  # Once allocation history/audit log has been refactored this won't be needed
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
    # There are still some locations we don't know about e.g. immigration detention centres
    # so this check has to allow PRISONS[code] to be nil
    PRISONS[code]&.gender == :female
  end

  # Deprecated because we have a proper model. Use @prison.name instead
  def self.name_for(code)
    PRISONS[code]&.name
  end
end
