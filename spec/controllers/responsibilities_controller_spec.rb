# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponsibilitiesController, type: :controller do
  before do
    create(:case_information, local_delivery_unit: build(:local_delivery_unit))

    stub_sso_data(prison.code, email: sso_email_address)

    allow(ResponsibilityMailer).to receive(:with).and_return(
      double(
        responsibility_to_custody: responsibility_to_custody_mailer,
        responsibility_to_custody_with_pom: responsibility_to_custody_with_pom_mailer
      )
    )
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
  let(:responsibility_override_mailer) { double(:responsibility_override_mailer, deliver_later: nil) }

  describe '#new' do
    before do
      stub_offender(nomis_offender)
    end

    context 'when a responsibility override already exists' do
      render_views

      before do
        create(:responsibility, nomis_offender_id: offender_no)
      end

      it 'renders an error page explaining the override already exists' do
        get :new, params: { prison_id: prison.code, nomis_offender_id: offender_no }

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:presence_error)
          expect(response.body).to include(prison_prisoner_allocation_path(prison.code, offender_no))
        end
      end
    end
  end

  describe '#confirm' do
    before do
      stub_offender(nomis_offender)
    end

    context 'when a responsibility override already exists' do
      render_views

      before do
        create(:responsibility, nomis_offender_id: offender_no)
      end

      it 'renders an error page instead of allowing confirmation' do
        post :confirm, params: {
          prison_id: prison.code,
          responsibility: {
            nomis_offender_id: offender_no,
            reason: :less_than_10_months_to_serve,
          }
        }

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:presence_error)
          expect(response.body).to include(prison_prisoner_allocation_path(prison.code, offender_no))
        end
      end
    end
  end

  describe '#create' do
    let(:message) { 'Useful context for the community team' }

    before do
      stub_offender(nomis_offender)

      allow(PomMailer).to receive(:with)
        .and_return(double(responsibility_override: responsibility_override_mailer))
    end

    it 'creates a responsibility override and sends emails when one does not already exist' do
      expect {
        post :create, params: {
          prison_id: prison.code,
          responsibility: {
            nomis_offender_id: offender_no,
            reason: :less_than_10_months_to_serve,
            message:,
          }
        }
      }.to change(Responsibility, :count).by(1)

      aggregate_failures do
        expect(response).to redirect_to(prison_prisoner_allocation_path(prison.code, offender_no))
        expect(PomMailer).to have_received(:with).with(
          message:,
          prisoner_number: offender_no,
          prisoner_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}",
          prison_name: prison.name,
          email: sso_email_address
        )
        expect(PomMailer).to have_received(:with).with(
          message:,
          prisoner_number: offender_no,
          prisoner_name: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}",
          prison_name: prison.name,
          email: offender.ldu_email_address
        )
        expect(responsibility_override_mailer).to have_received(:deliver_later).twice
      end
    end

    it 'reuses the existing responsibility override and does not send duplicate emails' do
      create(:responsibility, nomis_offender_id: offender_no)

      expect {
        post :create, params: {
          prison_id: prison.code,
          responsibility: {
            nomis_offender_id: offender_no,
            reason: :less_than_10_months_to_serve,
            message:,
          }
        }
      }.not_to change(Responsibility, :count)

      aggregate_failures do
        expect(response).to redirect_to(prison_prisoner_allocation_path(prison.code, offender_no))
        expect(PomMailer).not_to have_received(:with)
        expect(responsibility_override_mailer).not_to have_received(:deliver_later)
      end
    end

    it 'treats a uniqueness validation failure as an existing override and does not send duplicate emails' do
      existing_responsibility = create(:responsibility, nomis_offender_id: offender_no)
      unsaved_responsibility = Responsibility.new(nomis_offender_id: offender_no)
      unsaved_responsibility.errors.add(:nomis_offender_id, :taken)

      allow(Responsibility).to receive(:find_or_initialize_by)
        .and_return(unsaved_responsibility)
      allow(unsaved_responsibility).to receive(:save!)
        .and_raise(ActiveRecord::RecordInvalid.new(unsaved_responsibility))

      expect {
        post :create, params: {
          prison_id: prison.code,
          responsibility: {
            nomis_offender_id: offender_no,
            reason: :less_than_10_months_to_serve,
            message:,
          }
        }
      }.not_to change(Responsibility, :count)

      aggregate_failures do
        expect(assigns(:responsibility)).to eq(existing_responsibility)
        expect(response).to redirect_to(prison_prisoner_allocation_path(prison.code, offender_no))
        expect(PomMailer).not_to have_received(:with)
        expect(responsibility_override_mailer).not_to have_received(:deliver_later)
      end
    end
  end

  describe '#destroy' do
    before do
      create(:responsibility, nomis_offender_id: offender_no)
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
