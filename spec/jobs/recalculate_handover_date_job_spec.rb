RSpec.describe RecalculateHandoverDateJob, type: :job do
  let(:offender_no) { nomis_offender.fetch(:prisonerNumber) }
  let(:today) { Time.zone.now }
  let(:prison) { create(:prison) }
  let(:event) { instance_double DomainEvents::Event, :event, publish: nil }

  before do
    stub_auth_token
    allow(DomainEvents::EventFactory).to receive(:build_handover_event).and_return(event)
    allow(Rails.configuration).to receive(:allocation_manager_host).and_return 'https://test.example.com'
  end

  before use_events: true do
    stub_const('USE_EVENTS_TO_PUSH_HANDOVER_TO_DELIUS', true)
  end

  context "when the offender exists in both NOMIS and nDelius (happy path)" do
    before do
      stub_offender(nomis_offender)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), case_allocation: 'NPS', manual_entry: false)
    end

    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }

    it "recalculates the offender's handover dates and pushes them to the Community API", aggregate_failures: true do
      offender = OffenderService.get_offender(offender_no)

      expect(HmppsApi::CommunityApi).to receive(:set_handover_dates)
        .with(offender_no: offender_no,
              handover_start_date: offender.handover_start_date,
              responsibility_handover_date: offender.responsibility_handover_date
             )

      described_class.perform_now(offender_no)
      expect(event).not_to have_received(:publish)
    end

    it 'recalculates the offenders handover dates and publishes a domain event', use_events: true,
                                                                                 aggregate_failures: true do
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
      offender = OffenderService.get_offender(offender_no)
      described_class.perform_now(offender_no)

      expect(DomainEvents::EventFactory).to have_received(:build_handover_event).with(
        noms_number: offender.offender_no,
        host: 'https://test.example.com',
      )
      expect(event).to have_received(:publish).with(no_args)
      expect(HmppsApi::CommunityApi).not_to have_received(:set_handover_dates)
    end
  end

  context "when the offender doesn't exist in NOMIS" do
    before do
      stub_non_existent_offender(offender_no)
    end

    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }

    it 'does not push to the API' do
      expect(HmppsApi::CommunityApi).not_to receive(:set_handover_dates)
      described_class.perform_now(offender_no)
    end

    it 'does not publish an event', use_events: true do
      described_class.perform_now(offender_no)
      expect(event).not_to have_received(:publish)
    end
  end

  context "when the offender doesn't have a sentence in NOMIS" do
    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code, sentence: attributes_for(:sentence_detail, :unsentenced)) }

    before do
      stub_offender(nomis_offender)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), case_allocation: 'NPS')
    end

    it 'does not push to the API' do
      expect(HmppsApi::CommunityApi).not_to receive(:set_handover_dates)
      described_class.perform_now(offender_no)
    end

    it 'does not publish an event', use_events: true do
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
      # we don't care about setting handover dates in Delius for this test
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
    end

    context 'when there is no COM assigned' do
      context 'without an LDU' do
        before do
          create(:case_information, :nps, local_delivery_unit: nil, offender: build(:offender, nomis_offender_id: offender_no))
        end

        it 'does not send an email' do
          expect(CommunityMailer).not_to receive(:assign_com_less_than_10_months)
          described_class.perform_now(offender_no)
        end
      end

      context 'when there is an LDU' do
        let(:ldu) { build(:local_delivery_unit) }
        let!(:case_info) { create(:case_information, :nps, local_delivery_unit: ldu, offender: build(:offender, nomis_offender_id: offender_no)) }
        let(:one_day_later) { today + 1.day }
        let(:two_days_later) { today + 2.days }

        before do
          # because we are inlining jobs and calling original, this method gets called twice
          expect(CommunityMailer).to receive(:assign_com_less_than_10_months).at_least(:twice).with(
            email: ldu.email_address,
            prisoner_name: "#{nomis_offender.fetch(:firstName)} #{nomis_offender.fetch(:lastName)}",
            prisoner_number: offender_no,
            crn_number: case_info.crn,
            prison_name: PrisonService.name_for(nomis_offender.fetch(:prisonId))
          ).and_call_original
        end

        it 'sends an email and records the fact' do
          expect {
            described_class.perform_now(offender_no)
          }.to change(EmailHistory, :count).by(1)
        end

        it 'nags the LDU 48 hours later' do
          expect {
            described_class.perform_now(offender_no)
          }.to change(EmailHistory, :count).by(1)

          Timecop.travel one_day_later do
            expect {
              described_class.perform_now(offender_no)
            }.not_to change(EmailHistory, :count)
          end

          Timecop.travel two_days_later do
            expect {
              described_class.perform_now(offender_no)
            }.to change(EmailHistory, :count).by(1)
          end
        end
      end
    end

    context 'when a COM is assigned' do
      let(:ldu) { build(:local_delivery_unit) }

      before do
        create(:case_information, :nps, :with_com, local_delivery_unit: ldu, offender: build(:offender, nomis_offender_id: offender_no))
      end

      it 'does not send an email' do
        expect(CommunityMailer).not_to receive(:assign_com_less_than_10_months)
        described_class.perform_now(offender_no)
      end
    end
  end

  describe 're-calculation' do
    let!(:case_info) { create(:case_information, :nps, offender: build(:offender, nomis_offender_id: offender_no)) }
    let(:offender) { OffenderService.get_offender(offender_no) }

    before do
      stub_offender(nomis_offender)
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
    end

    context "when calculated handover dates don't exist yet for the offender" do
      let(:record) { case_info.offender.calculated_handover_date }
      let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }

      it 'creates a new record' do
        expect {
          described_class.perform_now(offender_no)
        }.to change(CalculatedHandoverDate, :count).by(1)

        expect(record.start_date).to eq(offender.handover_start_date)
        expect(record.handover_date).to eq(offender.responsibility_handover_date)
        expect(record.reason_text).to eq(offender.handover_reason)
        expect(record.responsibility).to eq(CalculatedHandoverDate::CUSTODY_ONLY)
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
          expect(existing_record.handover_date).to eq(offender.responsibility_handover_date)
          expect(existing_record.reason_text).to eq(offender.handover_reason)
        end
      end

      describe "when the dates haven't changed" do
        let(:existing_start_date) { offender.handover_start_date }
        let(:existing_handover_date) { offender.responsibility_handover_date }
        let(:existing_reason) { HandoverDateService.handover(offender).reason }

        it "does nothing" do
          old_updated_at = existing_record.updated_at

          travel_to(Time.zone.now + 15.minutes) do
            described_class.perform_now(offender_no)
          end

          new_updated_at = existing_record.reload.updated_at
          expect(new_updated_at).to eq(old_updated_at)
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
                                case_allocation: 'NPS', manual_entry: false)
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
    let(:policy_start_date) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE }

    before do
      stub_offender(nomis_offender)
      stub_movements_for(offender_no, [movement])
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)

      # Create an 'old' handover date, which will then be updated given the 'new' open conditions
      create(:calculated_handover_date, offender: case_information.offender,
                                        responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
                                        reason: :nps_indeterminate)
    end

    context 'when in a male prison' do
      it 'emails the LDU to notify them that a COM is now needed' do
        expect(CommunityMailer).to receive(:open_prison_supporting_com_needed)
                                     .with(hash_including(
                                             prisoner_number: offender_no,
                                             # prisoner_name: "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}",
                                             prisoner_crn: case_information.crn,
                                             ldu_email: case_information.ldu_email_address,
                                             prison_name: prison.name,
                                           ))
                                     .and_return OpenStruct.new(deliver_later: true)

        expect { described_class.perform_now(offender_no) }.to change(EmailHistory, :count).by(1)
      end
    end

    context 'when in a female prison' do
      let(:prison) { create(:womens_prison) }
      let(:category) { attributes_for(:offender_category, :female_open) }
      let(:policy_start_date) { HandoverDateService::WOMENS_POLICY_START_DATE }

      it 'emails the LDU to notify them that a COM is now needed' do
        expect(CommunityMailer).to receive(:open_prison_supporting_com_needed)
                                     .with(hash_including(
                                       # prisoner_number: offender_no,
                                       # prisoner_name: "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}",
                                       prisoner_crn: case_information.crn,
                                       ldu_email: case_information.ldu_email_address,
                                       prison_name: prison.name,
                                     ))
                                     .and_return OpenStruct.new(deliver_later: true)

        expect { described_class.perform_now(offender_no) }.to change(EmailHistory, :count).by(1)
      end
    end

    context 'when the LDU email address is unknown' do
      let!(:case_information) do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no),
                                  local_delivery_unit: nil,
                                  case_allocation: 'NPS', manual_entry: true)
      end

      it 'does not send an email' do
        expect(CommunityMailer).not_to receive(:open_prison_supporting_com_needed)
        expect { described_class.perform_now(offender_no) }.not_to change(EmailHistory, :count)
      end
    end

    context 'when a COM is already allocated' do
      let!(:case_information) do
        create(:case_information, :with_com, offender: build(:offender, nomis_offender_id: offender_no),
                                             case_allocation: 'NPS', manual_entry: false)
      end

      it 'does not send an email' do
        expect(CommunityMailer).not_to receive(:open_prison_supporting_com_needed)
        expect { described_class.perform_now(offender_no) }.not_to change(EmailHistory, :count)
      end
    end
  end
end
