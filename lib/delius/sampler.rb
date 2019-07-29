# frozen_string_literal: true

require 'csv'

module Delius
  class Sampler
    HEADERS = ['CRN', 'PNC No', 'NOMS No', 'Fullname (O)', 'Tier Cd (OMT)',
      'Risk Of Harm Cds', 'Offender Manager', 'Organisation Private Ind (OfM)',
      'Organisation (OfM)', 'Provider (OfM)', 'Provider Cd (OfM)', 'LDU (OfM) ',
      'LDU Cd (OfM)', 'Team (OfM)', 'Team Cd (OfM)', 'MAPPA Y/N', 'MAPPA Levels']

    def initialize(target_filename)
      @output_file = target_filename
      @offenders = OffenderService.get_offenders_for_prison('LEI').to_a
      @crn_root = 0
      @pnc_root = 100000
    end

    def generate(count)
      CSV.open(@output_file, "wb", write_headers: true, headers: HEADERS ) do |csv|
          count.times { |_i|
            csv << generate_row
          }
      end
    end

  private

    def generate_row
      offender = @offenders.pop
      mappa_yesno = approximately(0.5, 'Y', 'N')

      [
       (@crn_root += 1).to_s.rjust(4, '0'),
       approximately(0.8, "PNC/00#{@pnc_root -= 1}", ''),
       approximately(0.97, offender.offender_no, ''),
       offender.full_name,
       '',
       '',
       '',
       '',
       '',
       '',
       '',
       '',
       '',
       '',
       '',
       mappa_yesno,
       mappa_yesno == 'Y' ? ['1', '2', '3', '1', '2', '3', 'Nominal'].sample : ''
      ]
    end


    # percent_of_the_time should be a value between 0 and 1.
    # This is far from exact, it's just an approximation
    def approximately(percent_of_the_time, give_this, otherwise_this)
      return give_this if rand(0.0...1.0) <= percent_of_the_time

      otherwise_this
    end
  end
end

