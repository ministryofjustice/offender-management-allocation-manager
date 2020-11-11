require 'rails_helper'

RSpec.describe CommunityMailer, type: :mailer do
  describe 'handover_chase_email' do
    let(:offender) { build(:offender, latestLocationId: 'LEI') }

    let(:case_info) do
      create(:case_information, nomis_offender_id: offender.offender_no,
             responsibility: build(:responsibility, nomis_offender_id: offender.offender_no))
    end

    let(:params) do
      {
      nomis_offender_id: offender.offender_no,
      offender_name: offender.full_name,
      offender_crn: offender.crn,
      sentence_type: 'Determinate',
      ldu_email: offender.ldu.email_address,
      prison: PrisonService.name_for('LEI'),
      start_date: 'Mon, 13 June 2024',
      responsibility_handover_date: 'Wed, 15 Aug 2024',
      pom_name: "Richards, Ursula",
      pom_email: "ursula.richards@thelighthouse.gov.uk"
      }
    end

    let(:mail) { described_class.urgent_pipeline_to_community(params) }

    before do
      offender.load_case_information(case_info)
    end

    it 'sets the template' do
      expect(mail.govuk_notify_template).to eq('d7366b11-c93e-48de-824f-cb80a9778e71')
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq([offender.ldu.email_address])
    end

    it 'personalises the email for handover' do
      expect(mail.govuk_notify_personalisation).
      to eq(email: params[:ldu_email],
            name: params[:offender_name],
            crn: params[:offender_crn],
            sentence_type: params[:sentence_type],
            noms_no: params[:nomis_offender_id],
            prison_name: params[:prison],
            start_date: params[:start_date],
            responsibility_handover_date: params[:responsibility_handover_date],
            pom_name: params[:pom_name],
            pom_email: params[:pom_email]
         )
    end
  end
end
