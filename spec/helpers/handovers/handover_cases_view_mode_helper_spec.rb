RSpec.describe Handovers::HandoverCasesViewModeHelper do
  describe '#handover_cases_view' do
    let(:current_user) { double :current_user }
    let(:prison) { double :prison }
    let(:pom_handover_cases) { instance_double Handover::CategorisedHandoverCasesForPom, :pom_handover_cases }
    let(:homd_handover_cases) { instance_double Handover::CategorisedHandoverCasesForHomd, :homd_handover_cases }

    before do
      allow(Handover::CategorisedHandoverCasesForPom).to receive(:new).with(current_user).and_return(pom_handover_cases)
      allow(Handover::CategorisedHandoverCasesForHomd).to receive(:new).with(prison).and_return(homd_handover_cases)
    end

    describe 'when only a POM' do
      it 'fetches POM handover cases' do
        result = helper.handover_cases_view(current_user: current_user,
                                            prison: prison,
                                            current_user_is_pom: true,
                                            current_user_is_spo: false)
        expect(result).to eq [true, pom_handover_cases]
      end
    end

    describe 'when only HOMD, regardless of POM flag' do
      it 'fetches HOMD handover cases' do
        result = helper.handover_cases_view(current_user: current_user,
                                            prison: prison,
                                            current_user_is_pom: false,
                                            current_user_is_spo: true,
                                            pom_param: '1')
        expect(result).to eq [false, homd_handover_cases]
      end
    end

    describe 'when a POM and HOMD' do
      describe 'and POM flag is disabled' do
        it 'fetches HOMD handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: true,
                                              current_user_is_spo: true)
          expect(result).to eq [false, homd_handover_cases]
        end
      end

      describe 'and POM flag is enabled' do
        it 'fetches POM handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: true,
                                              current_user_is_spo: true,
                                              pom_param: '1')
          expect(result).to eq [true, pom_handover_cases]
        end
      end

      describe 'when neither POM or HOMD' do
        it 'returns nil' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: false,
                                              current_user_is_spo: false)
          expect(result).to eq nil
        end
      end
    end
  end
end
