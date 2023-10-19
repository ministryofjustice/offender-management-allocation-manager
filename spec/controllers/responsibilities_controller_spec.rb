# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponsibilitiesController, type: :controller do
  before do
    offender = create(:case_information, local_delivery_unit: build(:local_delivery_unit))
    create(:responsibility, nomis_offender_id: offender.nomis_offender_id)

    stub_sso_data(prison.code, emails: [sso_email_address])

    allow(ResponsibilityMailer).to receive(:with).and_return(double(responsibility_to_custody: responsibility_to_custody_mailer,
                                                                    responsibility_to_custody_with_pom: responsibility_to_custody_with_pom_mailer))
  end

  let(:case_info) { CaseInformation.last }
  let(:offender_no) { case_info.nomis_offender_id }
  let(:responsibility) { Responsibility.last }
  let(:prison) { create(:prison) }
  let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code, prisonerNumber: offender_no) }
  let(:reason) { 'Just because' }
  let(:sso_email_address) { Faker::Internet.email }
  let(:offender) { OffenderService.get_offender(offender_no) }
  let(:responsibility_to_custody_mailer) { double(:responsibility_to_custody_mailer, deliver_later: nil) }
  let(:responsibility_to_custody_with_pom_mailer) { double(:responsibility_to_custody_with_pom_mailer, deliver_later: nil) }

  describe '#destroy' do
    before do
      stub_offender(nomis_offender)
    end

    context 'without an allocation' do
      it 'destroys and sends an email to the LDU and the SPO' do
        aggregate_failures do
          expect {
            delete :destroy, params: {
              prison_id: prison.code,
              nomis_offender_id: responsibility.nomis_offender_id,
              responsibility: attributes_for(:remove_responsibility_form,
                                             nomis_offender_id: responsibility.nomis_offender_id,
                                             reason_text: reason)
            }
          }.to change(Responsibility, :count).by(-1)
          expect(ResponsibilityMailer).to have_received(:with).with(
            emails: [sso_email_address, offender.ldu_email_address],
            prisoner_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}",
            prisoner_number: offender_no,
            prison_name: prison.name,
            notes: reason)
          expect(responsibility_to_custody_mailer).to have_received(:deliver_later)
        end
      end
    end

    context 'with an allocation' do
      before do
        create(:allocation_history, prison: prison.code, nomis_offender_id: responsibility.nomis_offender_id, primary_pom_nomis_id: pom.staffId)
        stub_poms(prison.code, [pom])
      end

      let(:pom) { build(:pom) }
      let(:allocation) { AllocationHistory.last }

      it 'copies in the POM' do
        delete :destroy, params: {
          prison_id: prison.code,
          nomis_offender_id: responsibility.nomis_offender_id,
          responsibility: attributes_for(:remove_responsibility_form,
                                         nomis_offender_id: responsibility.nomis_offender_id,
                                         reason_text: reason)
        }

        aggregate_failures do
          expect(ResponsibilityMailer).to have_received(:with).with(
            emails: [sso_email_address, offender.ldu_email_address, pom.emails.first],
            prisoner_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}",
            prisoner_number: offender_no,
            prison_name: prison.name,
            pom_name: allocation.primary_pom_name,
            pom_email: pom.emails.first,
            notes: reason)
          expect(responsibility_to_custody_with_pom_mailer).to have_received(:deliver_later)
        end
      end
    end
  end
end
