RSpec.describe RecalculateHandoverDateJob, type: :job do
  let(:offender_no) { nomis_offender.fetch(:prisonerNumber) }
  let(:today) { Time.zone.now }
  let(:prison) { create(:prison) }
  let(:event) { instance_double DomainEvents::Event, :event, publish: nil }
  let(:assign_com_less_than_10_months_mailer) { double :assign_com_less_than_10_months_mailer, deliver_later: nil }
  let(:open_prison_supporting_com_needed_mailer) { double :open_prison_supporting_com_needed_mailer, deliver_later: nil }
  let(:community_mailer_with) do
    double(:community_mailer_with,
           assign_com_less_than_10_months: assign_com_less_than_10_months_mailer,
           open_prison_supporting_com_needed: open_prison_supporting_com_needed_mailer)
  end
  let(:published_args) { {} }

  before do
    allow(DomainEvents::EventFactory).to receive(:build_handover_event).and_return(event)
    allow(Rails.configuration).to receive(:allocation_manager_host).and_return 'https://test.example.com'
    allow(CommunityMailer).to receive(:with).and_return(community_mailer_with)
    allow(AuditEvent).to receive(:publish) { |**args| published_args.replace(args) }
  end

  context 'when offender\'s case does not have a handover date' do
    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:offender) { OffenderService.get_offender(offender_no) }

    before do
      stub_offender(nomis_offender)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), enhanced_resourcing: true, manual_entry: false)
      FactoryBot.create(:calculated_handover_date, :before_handover, nomis_offender_id: offender_no)
      offender # instantiate it after the previous lines
      allow(HandoverDateService).to receive(:handover).and_return(OffenderHandover::COM_NO_HANDOVER_DATE)

      described_class.perform_now(offender_no)
    end

    it 'publishes handover.changed domain event', aggregate_failures: true do
      expect(event).to have_received(:publish)
    end
  end

  context "when the offender exists in both NOMIS and nDelius (happy path)" do
    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:offender) { OffenderService.get_offender(offender_no) }

    before do
      stub_offender(nomis_offender)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), enhanced_resourcing: true, manual_entry: false)
      offender # instantiate it after the previous lines

      described_class.perform_now(offender_no)
    end

    it 'recalculates the offenders handover dates and publishes a domain event', aggregate_failures: true do
      expect(DomainEvents::EventFactory).to have_received(:build_handover_event).with(
        noms_number: offender.offender_no,
        host: 'https://test.example.com',
      )
      expect(event).to have_received(:publish).with(job: 'recalculate_handover_date')
    end

    it 'publishes an audit event', aggregate_failures: true do
      handover = CalculatedHandoverDate.find_by(nomis_offender_id: offender_no)
      expect(AuditEvent).to have_received(:publish)
      expect(published_args.keys).to match_array(%i[nomis_offender_id system_event tags data])
      expect(published_args[:nomis_offender_id]).to eq(offender_no)
      expect(published_args[:system_event]).to eq true
      expect(published_args[:tags]).to match_array %w[job recalculate_handover_date handover changed]
      expect(published_args[:data]).to be_a(Hash)

      expect(published_args[:data]['before'].keys).to include('handover_date', 'start_date', 'responsibility', 'reason')
      expect(published_args[:data]['before'].keys).not_to include('id', 'created_at', 'updated_at')
      expect(published_args[:data]['after'].values_at('handover_date', 'start_date', 'responsibility', 'reason'))
                                 .to eq([handover.handover_date, handover.start_date, 'CustodyOnly', 'determinate'])
      expect(published_args[:data]['after'].keys).not_to include('id', 'created_at', 'updated_at')
    end
  end

  context "when the offender doesn't exist in NOMIS" do
    before do
      stub_non_existent_offender(offender_no)
    end

    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }

    it 'does not publish an event' do
      described_class.perform_now(offender_no)
      expect(event).not_to have_received(:publish)
    end
  end

  context "when the offender doesn't have a sentence in NOMIS" do
    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code, sentence: attributes_for(:sentence_detail, :unsentenced)) }

    before do
      stub_offender(nomis_offender)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), enhanced_resourcing: true)
    end

    it 'does not publish an event' do
      described_class.perform_now(offender_no)
      expect(event).not_to have_received(:publish)
    end
  end

  context 'when offender has less than 10 months left to serve' do
    let(:nomis_offender) do
      build(:nomis_offender,
            prisonId: prison.code,
            sentence: attributes_for(:sentence_detail, :less_than_10_months_to_serve))
    end

    before do
      stub_offender(nomis_offender)
    end

    context 'when there is no COM assigned' do
      context 'without an LDU' do
        before do
          create(:case_information, enhanced_resourcing: true, local_delivery_unit: nil, offender: build(:offender, nomis_offender_id: offender_no))
        end

        it 'does not send an email' do
          expect(CommunityMailer).not_to receive(:assign_com_less_than_10_months)
          described_class.perform_now(offender_no)
        end
      end

      context 'when there is an LDU' do
        let(:ldu) { build(:local_delivery_unit) }
        let!(:case_info) { create(:case_information, enhanced_resourcing: true, local_delivery_unit: ldu, offender: build(:offender, nomis_offender_id: offender_no)) }
        let(:one_day_later) { today + 1.day }
        let(:two_days_later) { today + 2.days }

        it 'nags the LDU 48 hours later' do
          allow(CommunityMailer).to receive(:with).and_call_original
          ActiveJob::Base.queue_adapter = :test

          expected_params = {
            params: {
              email: ldu.email_address,
              email_history_name: ldu.name,
              prison_name: PrisonService.name_for(nomis_offender.fetch(:prisonId)),
              prisoner_name: "#{nomis_offender.fetch(:firstName)} #{nomis_offender.fetch(:lastName)}",
              prisoner_number: offender_no,
              crn_number: case_info.crn
            },
            args: []
          }

          expect { described_class.perform_now(offender_no) }
            .to have_enqueued_job(ActionMailer::MailDeliveryJob)
            .with('CommunityMailer', 'assign_com_less_than_10_months', 'deliver_now', expected_params)

          create(:email_history, event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION, nomis_offender_id: offender_no)

          Timecop.travel one_day_later do
            expect { described_class.perform_now(offender_no) }
            .not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
          end

          Timecop.travel two_days_later do
            expect { described_class.perform_now(offender_no) }
            .to have_enqueued_job(ActionMailer::MailDeliveryJob)
            .with('CommunityMailer', 'assign_com_less_than_10_months', 'deliver_now', expected_params)
          end
        end
      end
    end

    context 'when a COM is assigned' do
      let(:ldu) { build(:local_delivery_unit) }

      before do
        create(:case_information, :with_com, enhanced_resourcing: true, local_delivery_unit: ldu, offender: build(:offender, nomis_offender_id: offender_no))
      end

      it 'does not send an email' do
        expect(CommunityMailer).not_to receive(:assign_com_less_than_10_months)
        described_class.perform_now(offender_no)
      end
    end
  end

  describe 're-calculation' do
    let!(:case_info) { create(:case_information, enhanced_resourcing: true, offender: build(:offender, nomis_offender_id: offender_no)) }
    let(:offender) { OffenderService.get_offender(offender_no) }

    before do
      stub_offender(nomis_offender)
    end

    context "when calculated handover dates don't exist yet for the offender" do
      let(:record) { case_info.offender.calculated_handover_date }
      let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }

      it 'creates a new record' do
        expect {
          described_class.perform_now(offender_no)
        }.to change(CalculatedHandoverDate, :count).by(1)

        expect(record.start_date).to eq(offender.handover_start_date)
        expect(record.handover_date).to eq(offender.handover_date)
        expect(record.reason_text).to eq(offender.handover_reason)
        expect(record.responsibility).to eq(CalculatedHandoverDate::CUSTODY_ONLY)
        expect(record.last_calculated_at.class).to eq(ActiveSupport::TimeWithZone)
      end

      context 'with a COM responsible case' do
        let(:nomis_offender) do
          build(:nomis_offender,
                prisonId: prison.code,
                sentence: attributes_for(:sentence_detail, :less_than_10_months_to_serve))
        end

        it 'records responsibility' do
          described_class.perform_now(offender_no)
          expect(record.responsibility).to eq(CalculatedHandoverDate::COMMUNITY_RESPONSIBLE)
        end
      end
    end

    context 'when calculated handover dates already exist for the offender' do
      let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }
      let!(:existing_record) do
        create(:calculated_handover_date,
               responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
               offender: case_info.offender,
               start_date: existing_start_date,
               handover_date: existing_handover_date,
               reason: existing_reason
              )
      end

      describe 'when the dates have changed' do
        let(:existing_start_date) { today + 1.week }
        let(:existing_handover_date) { existing_start_date + 7.months }
        let(:existing_reason) { :crc_case }

        it 'updates the existing record' do
          described_class.perform_now(offender_no)

          existing_record.reload
          expect(existing_record.start_date).to eq(offender.handover_start_date)
          expect(existing_record.handover_date).to eq(offender.handover_date)
          expect(existing_record.reason_text).to eq(offender.handover_reason)
          expect(existing_record.last_calculated_at.class).to eq(ActiveSupport::TimeWithZone)
        end
      end

      describe "when the dates haven't changed" do
        let(:existing_start_date) { Date.new(2100, 12, 1) }
        let(:existing_handover_date) { Date.new(2100, 12, 1) }
        let(:existing_reason) { 'determinate' }

        before do
          allow(HandoverDateService).to receive(:handover).and_return(
            CalculatedHandoverDate.new(responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
                                       start_date: existing_start_date,
                                       handover_date: existing_handover_date,
                                       reason: existing_reason)
          )
        end

        it "does nothing" do
          old_attributes = existing_record.attributes

          travel_to(Time.zone.now + 15.minutes) do
            described_class.perform_now(offender_no)
          end

          new_attributes = existing_record.reload.attributes
          expect(new_attributes).to eq(old_attributes)
        end
      end
    end
  end

  context 'when an indeterminate offender has moved into open conditions' do
    let(:nomis_offender) do
      build(:nomis_offender,
            prisonId: prison.code,
            category: category,
            sentence: attributes_for(:sentence_detail,
                                     :indeterminate,
                                     sentenceStartDate: sentence_start_date))
    end

    let!(:case_information) do
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no),
                                enhanced_resourcing: true, manual_entry: false)
    end

    let(:movement) do
      attributes_for(:movement,
                     toAgency: prison.code,
                     offenderNo: offender_no,
                     movementDate: movement_date.to_s)
    end

    let(:offender) { build(:nomis_offender, prisonId: prison.code, prisonerNumber: offender_no) }
    let(:sentence_start_date) { policy_start_date }
    let(:movement_date) { policy_start_date + 1.week }

    # Default: male offender
    let(:prison) { create(:prison, :open) }
    let(:category) { attributes_for(:offender_category, :cat_d) }
    let(:policy_start_date) { Offenders::PrisonPolicies::OPEN_PRISON_POLICY_START_DATE }

    before do
      stub_offender(nomis_offender)
      stub_movements_for(offender_no, [movement])

      # Create an 'old' handover date, which will then be updated given the 'new' open conditions
      create(:calculated_handover_date, offender: case_information.offender,
                                        responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
                                        reason: :indeterminate)
    end

    context 'when in a male prison' do
      it 'emails the LDU to notify them that a COM is now needed', :aggregate_failures do
        described_class.perform_now(offender_no)

        expect(CommunityMailer).to have_received(:with).with(
          hash_including(
            prisoner_number: offender_no,
            prisoner_crn: case_information.crn,
            ldu_email: case_information.ldu_email_address,
            prison_name: prison.name
          )
        )
        expect(open_prison_supporting_com_needed_mailer).to have_received(:deliver_later)
      end
    end

    context 'when in a female prison' do
      let(:prison) { create(:womens_prison) }
      let(:category) { attributes_for(:offender_category, :female_open) }
      let(:policy_start_date) { Offenders::PrisonPolicies::WOMENS_POLICY_START_DATE }

      it 'emails the LDU to notify them that a COM is now needed', :aggregate_failures do
        described_class.perform_now(offender_no)

        expect(CommunityMailer).to have_received(:with)
                                     .with(hash_including(
                                             prisoner_crn: case_information.crn,
                                             ldu_email: case_information.ldu_email_address,
                                             prison_name: prison.name,
                                           ))
        expect(open_prison_supporting_com_needed_mailer).to have_received(:deliver_later)
      end
    end

    context 'when the LDU email address is unknown' do
      let!(:case_information) do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no),
                                  local_delivery_unit: nil,
                                  enhanced_resourcing: true, manual_entry: true)
      end

      it 'does not send an email' do
        expect(CommunityMailer).not_to receive(:open_prison_supporting_com_needed)
        expect { described_class.perform_now(offender_no) }.not_to change(EmailHistory, :count)
      end
    end

    context 'when a COM is already allocated' do
      let!(:case_information) do
        create(:case_information, :with_com, offender: build(:offender, nomis_offender_id: offender_no),
                                             enhanced_resourcing: true, manual_entry: false)
      end

      it 'does not send an email' do
        expect(CommunityMailer).not_to receive(:open_prison_supporting_com_needed)
        expect { described_class.perform_now(offender_no) }.not_to change(EmailHistory, :count)
      end
    end
  end
end
