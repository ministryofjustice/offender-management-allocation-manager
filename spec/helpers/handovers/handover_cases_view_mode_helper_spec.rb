RSpec.describe Handovers::HandoverCasesViewModeHelper do
  describe '#handover_cases_view' do
    let(:current_user) { double :current_user }
    let(:other_pom) { double :current_user }
    let(:prison) { double :prison }
    let(:pom_handover_cases) { instance_double Handover::CategorisedHandoverCasesForPom, :pom_handover_cases }
    let(:homd_handover_cases) { instance_double Handover::CategorisedHandoverCasesForHomd, :homd_handover_cases }

    before do
      allow(Handover::CategorisedHandoverCasesForPom).to receive(:new).with(current_user).and_return(pom_handover_cases)
      allow(Handover::CategorisedHandoverCasesForPom).to receive(:new).with(other_pom).and_return(pom_handover_cases)
      allow(Handover::CategorisedHandoverCasesForHomd).to receive(:new).with(prison).and_return(homd_handover_cases)
    end

    describe 'when user is a POM' do
      it 'fetches POM handover cases' do
        result = helper.handover_cases_view(current_user: current_user,
                                            prison: prison,
                                            current_user_is_pom: true,
                                            current_user_is_spo: false)
        expect(result).to eq pom_handover_cases
      end
    end

    describe 'when user is just a HOMD' do
      context 'and wants all cases' do
        it 'fetches HOMD handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: false,
                                              current_user_is_spo: true)
          expect(result).to eq homd_handover_cases
        end
      end

      context 'and wants cases for a specific POM' do
        it 'fetches POM handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: false,
                                              current_user_is_spo: true,
                                              for_pom: other_pom)
          expect(result).to eq pom_handover_cases
        end
      end
    end

    describe 'when user is a POM and a HOMD' do
      describe 'and wants all cases' do
        it 'fetches HOMD handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: true,
                                              current_user_is_spo: true)
          expect(result).to eq homd_handover_cases
        end
      end

      describe 'and wants just their cases' do
        it 'fetches POM handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: true,
                                              current_user_is_spo: true,
                                              for_pom: 'user')
          expect(result).to eq pom_handover_cases
        end
      end

      context 'and wants cases for a specific POM' do
        it 'fetches POM handover cases' do
          result = helper.handover_cases_view(current_user: current_user,
                                              prison: prison,
                                              current_user_is_pom: true,
                                              current_user_is_spo: true,
                                              for_pom: other_pom)
          expect(result).to eq pom_handover_cases
        end
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
