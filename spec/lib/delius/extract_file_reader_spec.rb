require 'rails_helper'
require 'delius/extract_file_reader'

describe Delius::ExtractFileReader do
  subject { described_class.new(filename) }

  let(:filename) { 'spec/fixtures/delius/delius_sample.xlsx' }

  it 'returns an Enumerable' do
    expect(subject).to be_an(Enumerable)
  end

  it 'returns the expected number of records' do
    # The fixture file contains 93 rows: 1 header row + 92 Delius records
    # Header row is skipped
    expect(subject.count).to eq(92)
  end

  it 'returns Delius records as Hashes' do
    first_record = {
      crn: 'crn code',
      pnc_no: 'pnc num',
      noms_no: 'mangled nomis',
      fullname: 'Bobby Pin',
      tier: 'C2',
      roh_cds: 'risk of harm',
      offender_manager: 'ROSS JONES',
      org_private_ind: 'Y',
      org: 'CRC',
      provider: 'NPS',
      provider_code: 'C1234',
      ldu: 'NPS Trafford',
      ldu_code: 'N01TRF',
      team: 'Team 1',
      team_code: 'A',
      mappa: 'N',
      mappa_levels: '1',
      date_of_birth: '19/03/1985'
    }

    last_record = {
      crn: 'crn code',
      pnc_no: 'pnc num',
      noms_no: 'G3356GT',
      fullname: 'Bobby Pin',
      tier: 'A1',
      roh_cds: 'risk of harm',
      offender_manager: 'ROSS JONES',
      org_private_ind: 'N',
      org: 'NPS',
      provider: 'NPS',
      provider_code: 'C1234',
      ldu: 'NPS Bolton',
      ldu_code: 'N014403',
      team: 'Team 1',
      team_code: 'A',
      mappa: 'Y',
      mappa_levels: '1',
      date_of_birth: '19/03/1985'
    }

    expect(subject.first).to eq(first_record)
    expect(subject.to_a.last).to eq(last_record)
  end

  context 'when the LDU and team names contain ampersands (&)' do
    # The 3rd record (row 4) contains ampersands
    let(:record) { subject.to_a[2] }

    it 'reads them correctly' do
      expect(record[:ldu]).to eq('Norfolk & Suffolk LDU')
      expect(record[:team]).to eq('N&S-Bury St Edmunds')
    end
  end

  context 'when the row contains an empty cell' do
    # The 10th record (row 11) has an empty 'tier' cell
    let(:record) { subject.to_a[9] }

    it 'still aligns field names and values correctly' do
      expect_record = {
        crn: 'crn code',
        pnc_no: 'pnc num',
        noms_no: 'mangled nomis',
        fullname: 'Bobby Pin',
        tier: '', # tier should be an empty string
        roh_cds: 'risk of harm',
        offender_manager: 'ROSS JONES',
        org_private_ind: 'N',
        org: 'CRC',
        provider: 'NPS',
        provider_code: 'N1234',
        ldu: 'Stoke LDU',
        ldu_code: 'SWM11G',
        team: 'Team 1',
        team_code: 'A',
        mappa: 'N',
        mappa_levels: '1',
        date_of_birth: '19/03/1985'
      }

      expect(record).to eq(expect_record)
    end

    it 'the empty cell becomes an empty string' do
      expect(record[:tier]).to eq('')
    end
  end
end
