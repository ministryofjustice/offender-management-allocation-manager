RSpec.describe Handovers::HandoverCasesViewModeHelper do
  describe '#handover_cases_view' do
    let(:current_user) { double :current_user, unreleased_allocations: double(:current_user_unreleased) }
    let(:prison) { double :prison, primary_allocated_offenders: double(:prison_primary_allocs) }
    let(:pom_handover_cases) { instance_double Handover::Summary, :pom_handover_cases }
    let(:pom_or_homd_as_pom_handover_cases) { instance_double Handover::Summary, :pom_or_homd_as_pom_handover_cases }
    let(:homd_handover_cases) { instance_double Handover::Summary, :homd_handover_cases }

    before do
      allow(Handover::Summary).to receive(:new)
        .with(current_user.unreleased_allocations)
        .and_return(pom_or_homd_as_pom_handover_cases)
      allow(Handover::Summary).to receive(:new)
        .with(prison.primary_allocated_offenders)
        .and_return(homd_handover_cases)
    end

    describe 'when user is a POM' do
      it 'fetches POM handover cases' do
        result = helper.handover_cases_view(current_user: current_user,
                                            prison: prison,
                                            current_user_is_pom: true,
                                            current_user_is_spo: false)
        expect(result).to eq pom_or_homd_as_pom_handover_cases
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
          expect(result).to eq pom_or_homd_as_pom_handover_cases
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
