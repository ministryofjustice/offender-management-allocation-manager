# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponsibilitiesController, type: :controller do
  let!(:case_info) { create(:case_information, local_delivery_unit: build(:local_delivery_unit)) }
  let(:offender_no) { case_info.nomis_offender_id }
  let(:responsibility) { Responsibility.last }
  let(:prison) { create(:prison) }
  let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code, prisonerNumber: offender_no) }
  let(:full_name) { "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}" }
  let(:reason) { 'Just because' }
  let(:from_param) { nil }
  let(:sso_email_address) { Faker::Internet.email }
  let(:offender) { OffenderService.get_offender(offender_no) }
  let(:responsibility_to_custody_mailer) { double(:responsibility_to_custody_mailer, deliver_later: nil) }
  let(:responsibility_to_custody_with_pom_mailer) { double(:responsibility_to_custody_with_pom_mailer, deliver_later: nil) }
  let(:responsibility_override_mailer) { double(:responsibility_override_mailer, deliver_later: nil) }

  before do
    stub_sso_data(prison.code, email: sso_email_address)

    allow(ResponsibilityMailer).to receive(:with).and_return(
      double(
        responsibility_to_custody: responsibility_to_custody_mailer,
        responsibility_to_custody_with_pom: responsibility_to_custody_with_pom_mailer
      )
    )
  end

  describe 'SPO-only access' do
    before do
      stub_high_level_staff_member_auth(prison: prison)
      allow(controller).to receive(:current_user_is_spo?).and_return(false)
    end

    it 'rejects non-SPO users' do
      get :new, params: { prison_id: prison.code, nomis_offender_id: offender_no }

      expect(response).to redirect_to('/401')
    end
  end

  shared_examples 'renders the presence error page' do
    render_views

    before do
      stub_offender(nomis_offender)
      create(:responsibility, nomis_offender_id: offender_no)
    end

    it 'renders the presence error page' do
      perform_request

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:presence_error)
        expect(response.body).to include(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
      end
    end

    context 'when coming from the allocation page' do
      let(:from_param) { 'allocation' }

      it 'links back to the allocation page' do
        perform_request

        expect(response.body).to include(prison_prisoner_allocation_path(prison.code, offender_no))
      end
    end
  end

  describe '#new' do
    subject(:perform_request) { get :new, params: { prison_id: prison.code, nomis_offender_id: offender_no, from: from_param } }

    include_examples 'renders the presence error page'
  end

  describe '#confirm' do
    subject(:perform_request) do
      post :confirm, params: {
        prison_id: prison.code,
        from: from_param,
        responsibility: {
          nomis_offender_id: offender_no,
          reason: :less_than_10_months_to_serve,
        }
      }
    end

    include_examples 'renders the presence error page'
  end

  describe '#create' do
    subject(:perform_request) { post :create, params: create_params }

    let(:message) { 'Useful context for the community team' }
    let(:create_params) do
      {
        prison_id: prison.code,
        from: from_param,
        responsibility: {
          nomis_offender_id: offender_no,
          reason: :less_than_10_months_to_serve,
          message:,
        }
      }
    end
    let(:override_mail_params) do
      {
        message:,
        prisoner_number: offender_no,
        prisoner_name: full_name,
        prison_name: prison.name,
      }
    end

    before do
      stub_offender(nomis_offender)

      allow(PomMailer).to receive(:with)
        .and_return(double(responsibility_override: responsibility_override_mailer))
    end

    it 'creates a responsibility override and sends emails when one does not already exist' do
      expect { perform_request }.to change(Responsibility, :count).by(1)

      aggregate_failures do
        expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
        expect_override_emails(sso_email_address, offender.ldu_email_address)
      end
    end

    context 'when coming from the allocation page' do
      let(:from_param) { 'allocation' }

      it 'redirects back to the allocation page' do
        perform_request

        expect(response).to redirect_to(prison_prisoner_allocation_path(prison.code, offender_no))
      end
    end

    it 'reuses the existing responsibility override and does not send duplicate emails' do
      create(:responsibility, nomis_offender_id: offender_no)

      expect { perform_request }.not_to change(Responsibility, :count)

      aggregate_failures do
        expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
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

      expect { perform_request }.not_to change(Responsibility, :count)

      aggregate_failures do
        expect(assigns(:responsibility)).to eq(existing_responsibility)
        expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
        expect(PomMailer).not_to have_received(:with)
        expect(responsibility_override_mailer).not_to have_received(:deliver_later)
      end
    end
  end

  describe '#destroy' do
    subject(:perform_request) { delete :destroy, params: destroy_params }

    let(:destroy_params) do
      {
        prison_id: prison.code,
        nomis_offender_id: responsibility.nomis_offender_id,
        from: from_param,
        responsibility: attributes_for(:remove_responsibility_form,
                                       nomis_offender_id: responsibility.nomis_offender_id,
                                       reason_text: reason)
      }
    end
    let(:removal_mail_params) do
      {
        prisoner_name: full_name,
        prisoner_number: offender_no,
        prison_name: prison.name,
        notes: reason,
      }
    end

    before do
      create(:responsibility, nomis_offender_id: offender_no)
      stub_offender(nomis_offender)
    end

    context 'without an allocation' do
      it 'destroys and sends an email to the LDU and the SPO' do
        aggregate_failures do
          expect { perform_request }.to change(Responsibility, :count).by(-1)
          expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
          expect_responsibility_removal_emails(
            mailer: responsibility_to_custody_mailer,
            emails: [sso_email_address, offender.ldu_email_address]
          )
        end
      end

      context 'when coming from the allocation page' do
        let(:from_param) { 'allocation' }

        it 'redirects back to the allocation page' do
          perform_request

          expect(response).to redirect_to(prison_prisoner_allocation_path(prison.code, offender_no))
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
      let(:with_pom_mail_params) do
        removal_mail_params.merge(
          pom_name: allocation.primary_pom_name,
          pom_email: pom.emails.first
        )
      end

      it 'copies in the POM' do
        perform_request

        aggregate_failures do
          expect_responsibility_removal_emails(
            mailer: responsibility_to_custody_with_pom_mailer,
            emails: [sso_email_address, offender.ldu_email_address, pom.emails.first],
            extra_params: with_pom_mail_params.except(:prisoner_name, :prisoner_number, :prison_name, :notes)
          )
        end
      end

      context 'when the signed-in user is also the allocated POM' do
        let(:pom) { build(:pom, emails: [sso_email_address]) }
        let(:with_pom_mail_params) do
          removal_mail_params.merge(
            pom_name: allocation.primary_pom_name,
            pom_email: pom.emails.first
          )
        end

        it 'only sends one email to that shared address' do
          perform_request

          aggregate_failures do
            expect(ResponsibilityMailer).to have_received(:with).with(with_pom_mail_params.merge(email: sso_email_address)).once
            expect_responsibility_removal_emails(
              mailer: responsibility_to_custody_with_pom_mailer,
              emails: [sso_email_address, offender.ldu_email_address],
              extra_params: with_pom_mail_params.except(:prisoner_name, :prisoner_number, :prison_name, :notes)
            )
          end
        end
      end

      context 'when looking up the allocated POM email fails' do
        before do
          allow(HmppsApi::NomisUserRolesApi).to receive(:email_address)
            .with(allocation.primary_pom_nomis_id)
            .and_raise(Faraday::ConnectionFailed.new('lookup failed'))
        end

        let(:with_pom_mail_params) do
          removal_mail_params.merge(
            pom_name: allocation.primary_pom_name,
            pom_email: nil
          )
        end

        it 'still sends the other responsibility removal emails' do
          aggregate_failures do
            expect { perform_request }.to change(Responsibility, :count).by(-1)

            expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
            expect_responsibility_removal_emails(
              mailer: responsibility_to_custody_with_pom_mailer,
              emails: [sso_email_address, offender.ldu_email_address],
              extra_params: with_pom_mail_params.except(:prisoner_name, :prisoner_number, :prison_name, :notes)
            )
          end
        end
      end
    end
  end

  def expect_override_emails(*emails)
    emails.each do |email|
      expect(PomMailer).to have_received(:with).with(override_mail_params.merge(email: email))
    end

    expect(responsibility_override_mailer).to have_received(:deliver_later).exactly(emails.size).times
  end

  def expect_responsibility_removal_emails(mailer:, emails:, extra_params: {})
    emails.each do |email|
      expect(ResponsibilityMailer).to have_received(:with).with(removal_mail_params.merge(extra_params).merge(email: email))
    end

    expect(mailer).to have_received(:deliver_later).exactly(emails.size).times
  end
end
