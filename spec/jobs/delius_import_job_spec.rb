require 'rails_helper'
require 'support/lib/mock_imap'
require 'support/lib/mock_mail'

RSpec.describe DeliusImportJob, type: :job do
  before do
    stub_const("Net::IMAP", MockIMAP)
    stub_const("Mail", MockMailMessage)

    # If you modify the fixture for this test, you will need to modify this list
    offenders = %w[G5823GP G3902GW G3757UN G3892UH G0135GA G8152UC G2541VV G3933UL
                   G1318GN G6877GE G5054VN G7975UA G3610VX G4739UP G0633UV G3140VC
                   G3873VI G6041UD G0126UD G1627GD G2316UN G6709GF G1237UD G2613GF
                   G9577VI G6217GE G4023GG G7350VX G4110UT G4971UN G9468UN G1970VH
                   G0723UO G4704UN G1531GV G9348UN G4664UV G5676GJ G1237GV G8156GT
                   G2214UP G5687GJ G1895GH G3086UD G3365UI G7984UU G1852UW G6168UN
                   G7913UN G3874UT G3122UF G8322UO G3321VF G2899VU G7747UD G6473UO
                   G6500UO G8242GE G8130VE G8918VU G1493UN G7166UG G2341UP G7633UV
                   G7218GI G5060GO G7704GG G3868UN G0661GP G0806UN G6754VV G7331GT
                   G4923UI G9577GE G2350UP G0686GT G5235GT G1955VA G7967UD G7142UL
                   G5497GU G3356GT GCA2H2A]
    offenders.each { |offender|
      stub_offender(build(:nomis_offender, offenderNo: offender))
    }
    stub_offender(build(:nomis_offender, offenderNo: 'mangled+nomis'))
    stub_auth_token
  end

  it 'doesnt crash' do
    ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_job'
    ENV['DELIUS_XLSX_PASSWORD'] = 'secret'

    expect {
      described_class.perform_now
    }.to change(DeliusData, :count).by(1)
    expect(DeliusData.last.crn).to eq('crn code')
    expect(DeliusData.last.tier).to eq('A1')
  end

  context 'when LDU and team names contain ampersands (&)' do
    it 'imports their names correctly' do
      ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_with_ampersands'
      ENV['DELIUS_XLSX_PASSWORD'] = 'secret'

      described_class.perform_now
      imported = DeliusData.first

      expect(imported.ldu).to eq('Norfolk & Suffolk LDU')
      expect(imported.team).to eq('N&S-Bury St Edmunds')
    end
  end

  context "when the shadow name doesn't begin with 'OMIC'" do
    it "captures an exception" do
      bad_shadow_name = 'Not a shadow team name'
      subject.process_decrypted_file([ldu_code: 'N01OMIC', ldu: 'An LDU', team_code: 'SHAD01', team: bad_shadow_name])
    end
  end

  context 'with tabs on the end of the team code' do
    it 'still works correctly due to stripping' do
      expect {
        subject.process_decrypted_file([ldu_code: 'N50LDU', ldu: 'An LDU', team_code: "NN01\t", team: 'Team Name'])
      }.to change(Team, :count).by(1)
    end
  end
end
