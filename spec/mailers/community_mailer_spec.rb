require 'rails_helper'

RSpec.describe CommunityMailer, type: :mailer do
  let(:prison) { build(:prison) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

  describe '#urgent_pipeline_to_community' do
    let(:api_offender) { build(:hmpps_api_offender, prisonId: 'LEI') }

    let(:case_info) do
      create(:case_information, offender: build(:offender, nomis_offender_id: api_offender.offender_no,
                                                           responsibility: build(:responsibility, nomis_offender_id: api_offender.offender_no)))
    end

    let(:params) do
      {
        nomis_offender_id: offender.offender_no,
        offender_name: offender.full_name,
        offender_crn: offender.crn,
        sentence_type: 'Determinate',
        ldu_email: offender.ldu_email_address,
        prison: Faker.name,
        start_date: 'Mon, 13 June 2024',
        responsibility_handover_date: 'Wed, 15 Aug 2024',
        pom_name: "Richards, Ursula",
        pom_email: "ursula.richards@thelighthouse.gov.uk"
      }
    end

    let(:mail) { described_class.with(**params).urgent_pipeline_to_community }

    it 'sets the template' do
      expect(mail.govuk_notify_template).to eq('d7366b11-c93e-48de-824f-cb80a9778e71')
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq([offender.ldu_email_address])
    end

    it 'personalises the email for handover' do
      expect(mail.govuk_notify_personalisation)
      .to eq(email: params[:ldu_email],
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

  describe '#pipeline_to_community' do
    subject { described_class.with(ldu:, csv_data: 'Comma, Separated, Values').pipeline_to_community }

    let(:ldu) { build(:local_delivery_unit) }

    it 'sends to the LDU email address' do
      expect(subject.to).to eq([ldu.email_address])
    end

    it 'sets the personalisation' do
      expect(
        subject.govuk_notify_personalisation
      ).to include(
        ldu_name: ldu.name,
        link_to_document: hash_including(
          file: a_kind_of(String),
          filename: "community_allocation_cases_#{ldu.code}.csv",
          confirm_email_before_download: nil,
          retention_period: nil
        )
      )
    end
  end

  describe '#pipeline_to_community_no_handovers' do
    subject { described_class.with(ldu:).pipeline_to_community_no_handovers }

    let(:ldu) { build(:local_delivery_unit) }

    it 'sends to the LDU email address' do
      expect(subject.to).to eq([ldu.email_address])
    end

    it 'sets the LDU name' do
      expect(subject.govuk_notify_personalisation).to include(ldu_name: ldu.name)
    end
  end

  describe '#open_prison_supporting_com_needed' do
    let(:api_offender) { build(:hmpps_api_offender, prisonId: PrisonService::PRESCOED_CODE, sentence_type: :indeterminate) }
    let(:case_info) do
      create(:case_information, :welsh, offender: build(:offender, nomis_offender_id: api_offender.offender_no,
                                                                   responsibility: build(:responsibility, nomis_offender_id: api_offender.offender_no)))
    end

    let(:params) do
      {
        prisoner_number: offender.offender_no,
        prisoner_name: offender.full_name,
        prisoner_crn: offender.crn,
        ldu_email: offender.ldu_email_address,
        prison_name: Faker.name
      }
    end

    let(:mail) { described_class.with(**params).open_prison_supporting_com_needed }

    it 'sets the template' do
      expect(mail.govuk_notify_template).to eq('51eea8d1-6c73-4b86-bac0-f74ad5573b43')
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq([offender.ldu_email_address])
    end

    it 'personalises the email for handover' do
      expect(mail.govuk_notify_personalisation)
      .to eq(prisoner_name: params[:prisoner_name],
             prisoner_number: params[:prisoner_number],
             prisoner_crn: params[:prisoner_crn],
             prison_name: params[:prison_name]
            )
    end
  end
end
