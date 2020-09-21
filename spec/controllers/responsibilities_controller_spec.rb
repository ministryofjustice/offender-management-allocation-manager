# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponsibilitiesController, type: :controller do
  before do
    offender = create(:case_information)
    create(:responsibility, nomis_offender_id: offender.nomis_offender_id)

    stub_sso_data(prison.code, emails: [sso_email_address])
  end

  let(:offender) { CaseInformation.last }
  let(:responsibility) { Responsibility.last }
  let(:prison) { build(:prison) }
  let(:nomis_offender) { build(:nomis_offender, offenderNo: offender.nomis_offender_id) }
  let(:reason) { 'Just because' }
  let(:sso_email_address) { Faker::Internet.email }

  describe '#destroy' do
    before do
      stub_offender(nomis_offender)
    end

    context 'without an allocation' do
      it 'destroys and sends an email to the LDU and the SPO' do
        allow_any_instance_of(ResponsibilityMailer).to receive(:responsibility_to_custody).with(
          emails: [sso_email_address, offender.local_divisional_unit.email_address],
          prisoner_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}",
          prisoner_number: offender.nomis_offender_id,
          prison_name: prison.name,
          notes: reason
        ).and_call_original
        expect {
          delete :destroy, params: {
              prison_id: prison.code,
              nomis_offender_id: responsibility.nomis_offender_id,
              responsibility: attributes_for(:remove_responsibility_form,
                                             nomis_offender_id: responsibility.nomis_offender_id,
                                             reason_text: reason)
          }
        }.to change(Responsibility, :count).by(-1)
      end
    end

    context 'with an allocation' do
      before do
        create(:allocation, nomis_offender_id: responsibility.nomis_offender_id, primary_pom_nomis_id: pom.staffId)
        stub_poms(prison.code, [pom])
      end

      let(:pom) { build(:pom) }
      let(:allocation) { Allocation.last }

      it 'copies in the POM' do
        allow_any_instance_of(ResponsibilityMailer).to receive(:responsibility_to_custody_with_pom).with(
          emails: [sso_email_address, offender.local_divisional_unit.email_address, pom.emails.first],
          prisoner_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}",
          prisoner_number: offender.nomis_offender_id,
          prison_name: prison.name,
          pom_name: allocation.primary_pom_name,
          pom_email: pom.emails.first,
          notes: reason
        ).and_call_original

        delete :destroy, params: {
            prison_id: prison.code,
            nomis_offender_id: responsibility.nomis_offender_id,
            responsibility: attributes_for(:remove_responsibility_form,
                                           nomis_offender_id: responsibility.nomis_offender_id,
                                           reason_text: reason)
        }
      end
    end
  end
end
