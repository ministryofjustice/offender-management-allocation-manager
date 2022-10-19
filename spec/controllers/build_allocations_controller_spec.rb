RSpec.describe BuildAllocationsController, type: :controller do
  let(:poms) { [build(:pom, :prison_officer, emails: [])] }
  let(:pom) { poms.first }
  let(:prison) { create(:prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    stub_poms(prison.code, poms)
    stub_signed_in_pom(prison.code, pom.staffId, 'Alice')
    stub_sso_data(prison.code)
    stub_offender(offender)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    stub_community_offender(offender_no, build(:community_data))
  end

  describe '#update' do
    let(:notes) { 'A note' }

    context 'when allocating' do
      before do
        put :update, params: {
          "allocation_form" => { "message" => notes },
          "prison_id" => prison.code,
          "prisoner_id" => offender_no,
          "staff_id" => pom.staffId,
          "id" => "allocate"
        }
      end

      it 'redirects' do
        expect(response.code).to eq('302')
      end

      it 'stores offender details' do
        expect(session).to have_key(:latest_allocation_details)
        expect(session[:latest_allocation_details]).to include(prisoner_number: offender_no,
                                                               additional_notes: notes)
      end
    end

    context 'when re-allocating' do
      before do
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no,
                                    primary_pom_nomis_id: pom_nomis_id)

        put :update, params: {
          "allocation_form" => { "message" => notes },
          "prison_id" => prison.code,
          "prisoner_id" => offender_no,
          "staff_id" => pom.staffId,
          "id" => "allocate"
        }
      end

      context 'with the same POM' do
        let(:pom_nomis_id) { pom.staffId }

        it 'redirects' do
          expect(response.code).to eq('302')
        end

        it 'does not store offender details' do
          expect(session).not_to have_key(:latest_allocation_details)
        end
      end

      context 'with a different POM' do
        let(:pom_nomis_id) { pom.staffId + 123 }

        it 'redirects' do
          expect(response.code).to eq('302')
        end

        it 'stores offender details' do
          expect(session).to have_key(:latest_allocation_details)
          expect(session[:latest_allocation_details]).to include(prisoner_number: offender_no, additional_notes: notes)
        end
      end
    end
  end
end
