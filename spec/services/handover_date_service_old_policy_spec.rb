# frozen_string_literal: true

require 'rails_helper'

describe HandoverDateService, 'old policy' do
  subject { described_class.handover(offender) }

  before do
    stub_const('USE_NEW_HANDOVER_POLICY', false)
  end

  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:pom) { OffenderManagerResponsibility.new subject.custody_responsible?, subject.custody_supporting?  }
  let(:com) { OffenderManagerResponsibility.new subject.community_responsible?, subject.community_supporting? }
  let(:start_date) { subject.start_date }
  let(:handover_date) { subject.handover_date }
  let(:reason) { subject.reason_text }
  let(:closed_prison) { 'LEI' }
  let(:prescoed_prison) { PrisonService::PRESCOED_CODE }
  let(:open_prison) { 'HVI' }
  let(:womens_prison) { create(:womens_prison).code }
  let(:prescoed_policy_start_date) { Date.new(2020, 10, 19) }
  let(:open_policy_start_date) { Date.new(2021, 3, 31) }
  let(:womens_policy_start_date) { Date.parse('30th April 2021') }
  let(:category) { build(:offender_category, :cat_c) }
  let(:today) { Time.zone.today }
  let(:arrival_date) { today }
  let(:welsh?) { false }
  let(:prison) { closed_prison }
  let(:sentence_start_date) { build(:sentence_detail, :english_policy_sentence).sentence_start_date }

  # Set the current date by changing the value of `today`
  before do
    Timecop.travel(today)
  end

  after do
    Timecop.return
  end

  context 'when determinate' do
    let(:today) { Date.parse('01/01/2021') }
    let(:crd) { Date.parse('01/09/2022') }
    let(:api_offender) do
      build(:hmpps_api_offender,
            prisonId: prison,
            sentence: attributes_for(:sentence_detail, :determinate, sentenceStartDate: sentence_start_date, conditionalReleaseDate: crd)
           ).tap do |o|
        o.prison_arrival_date = arrival_date
      end
    end

    context 'when NPS' do
      let(:case_info) { build(:case_information, :nps, probation_service: welsh? ? 'Wales' : 'England') }

      it 'handover starts 7.5 months before CRD/ARD' do
        expect(start_date).to eq(crd - (7.months + 15.days))
      end

      it 'handover happens 4.5 months before CRD/ARD' do
        expect(handover_date).to eq(crd - (4.months + 15.days))
      end

      describe 'before handover start date' do
        let(:today) { crd - (7.months + 16.days) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is not needed' do
          expect(com).not_to be_involved
        end
      end

      describe 'within the handover window' do
        let(:today) { crd - (7.months + 15.days) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is supporting' do
          expect(com).to be_supporting
        end
      end

      describe 'on/after handover date' do
        let(:today) { crd - (4.months + 15.days) }

        it 'POM is supporting' do
          expect(pom).to be_supporting
        end

        it 'COM is responsible' do
          expect(com).to be_responsible
        end
      end

      context 'when in a Womens prison' do
        let(:prison) { womens_prison }
        let(:arrival_date) { sentence_start_date }

        context 'when entering on or after the policy start date' do
          let(:sentence_start_date) { womens_policy_start_date }

          it 'follows policy rules' do
            expect(pom).to be_responsible
          end
        end

        context 'when entering before the policy start date' do
          let(:sentence_start_date) { womens_policy_start_date - 1.day }

          context 'with release on or after the cutoff date 30/9/2022' do
            let(:crd) { Date.parse('30/09/2022') }

            it 'follows policy rules' do
              expect(pom).to be_responsible
            end
          end

          context 'with release before the cutoff date 30/9/2022' do
            let(:crd) { Date.parse('29/09/2022') }

            it 'follows pre-policy rules' do
              expect(pom).to be_supporting
              expect(com).to be_responsible
              expect(start_date).to be_nil
              expect(handover_date).to be_nil
            end
          end
        end
      end

      context 'when in HMP Prescoed' do
        let(:prison) { prescoed_prison }

        context 'when Welsh offender entering on/after the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts 7.5 months before CRD/ARD' do
            expect(start_date).to eq(crd - (7.months + 15.days))
          end

          it 'handover happens 4.5 months before CRD/ARD' do
            expect(handover_date).to eq(crd - (4.months + 15.days))
          end

          describe 'before handover start date' do
            let(:today) { crd - (7.months + 16.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is not needed' do
              expect(com).not_to be_involved
            end
          end

          describe 'within the handover window' do
            let(:today) { crd - (7.months + 15.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { crd - (4.months + 15.days) }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end

        context 'when Welsh offender entering before the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date - 1.day }

          it 'is COM responsibility (pre-policy rules)' do
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end
        end

        context 'when English offender entering after the policy start date' do
          let(:welsh?) { false }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'is COM responsibility (pre-policy rules)' do
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end
        end
      end

      context 'when in an open prison' do
        let(:prison) { open_prison }

        context 'when offender enters on/after the policy start date' do
          let(:arrival_date) { open_policy_start_date }

          it 'handover starts 7.5 months before CRD/ARD' do
            expect(start_date).to eq(crd - (7.months + 15.days))
          end

          it 'handover happens 4.5 months before CRD/ARD' do
            expect(handover_date).to eq(crd - (4.months + 15.days))
          end

          describe 'before handover start date' do
            let(:today) { crd - (7.months + 16.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is not needed' do
              expect(com).not_to be_involved
            end
          end

          describe 'within the handover window' do
            let(:today) { crd - (7.months + 15.days) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { crd - (4.months + 15.days) }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end

        context 'when offender enters before the policy start date' do
          let(:arrival_date) { open_policy_start_date - 1.day }

          it 'is COM responsibility (pre-policy rules)' do
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end
        end
      end
    end

    context 'when CRC' do
      let(:case_info) { build(:case_information, :crc, probation_service: welsh? ? 'Wales' : 'England') }

      it 'handover starts 12 weeks before CRD/ARD' do
        expect(start_date).to eq(crd - 12.weeks)
      end

      it 'handover happens 12 weeks before CRD/ARD' do
        expect(handover_date).to eq(crd - 12.weeks)
      end

      describe 'before handover start date' do
        let(:today) { crd - (12.weeks + 1.day) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is not needed' do
          expect(com).not_to be_involved
        end
      end

      describe 'on/after handover date' do
        let(:today) { crd - 12.weeks }

        it 'POM is supporting' do
          expect(pom).to be_supporting
        end

        it 'COM is responsible' do
          expect(com).to be_responsible
        end
      end

      context 'when in HMP Prescoed' do
        let(:prison) { prescoed_prison }

        context 'when Welsh offender entering on/after the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end

        context 'when Welsh offender entering before the policy start date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date - 1.day }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end

        context 'when English offender entering after the policy start date' do
          let(:welsh?) { false }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end
      end

      context 'when in an open prison' do
        let(:prison) { open_prison }

        context 'when offender enters on/after the policy start date' do
          let(:arrival_date) { open_policy_start_date }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end

        context 'when offender enters before the policy start date' do
          let(:arrival_date) { open_policy_start_date - 1.day }

          it 'handover starts 12 weeks before CRD/ARD' do
            expect(start_date).to eq(crd - 12.weeks)
          end

          it 'handover happens 12 weeks before CRD/ARD' do
            expect(handover_date).to eq(crd - 12.weeks)
          end
        end
      end
    end
  end

  context 'when indeterminate' do
    context 'with tariff date in the future' do
      let(:tariff_date) { 1.year.from_now.to_date }
      let(:case_info) { build(:case_information, :nps, probation_service: welsh? ? 'Wales' : 'England') }
      let(:api_offender) do
        build(:hmpps_api_offender,
              prisonId: prison,
              category: category,
              sentence: attributes_for(:sentence_detail, :indeterminate, tariffDate: tariff_date, sentenceStartDate: sentence_start_date)
             ).tap do |o|
          o.prison_arrival_date = arrival_date
        end
      end

      it 'handover starts 8 months before TED/PED/PRD' do
        expect(start_date).to eq(tariff_date - 8.months)
      end

      it 'handover happens 8 months before TED/PED/PRD' do
        expect(handover_date).to eq(tariff_date - 8.months)
      end

      it 'gives reason "NPS Indeterminate"' do
        expect(reason).to eq("NPS Indeterminate")
      end

      describe 'before handover date' do
        let(:today) { tariff_date - (8.months + 1.day) }

        it 'POM is responsible' do
          expect(pom).to be_responsible
        end

        it 'COM is not needed' do
          expect(com).not_to be_involved
        end
      end

      describe 'on/after handover date' do
        let(:today) { tariff_date - 8.months }

        it 'POM is supporting' do
          expect(pom).to be_supporting
        end

        it 'COM is responsible' do
          expect(com).to be_responsible
        end
      end

      context 'when in HMP Prescoed' do
        let(:prison) { prescoed_prison }

        context 'when Welsh offender entering before the pilot date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date - 1.day }

          it 'is COM responsible (pre-OMIC rules)' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
          end
        end

        context 'when English offender entering on/after the pilot date' do
          let(:welsh?) { false }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'is COM responsible (pre-OMIC rules)' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
          end
        end

        context 'when Welsh offender entering on/after the pilot date' do
          let(:welsh?) { true }
          let(:arrival_date) { prescoed_policy_start_date }

          it 'handover starts the day they arrive at the prison' do
            expect(start_date).to eq(offender.prison_arrival_date)
          end

          it 'handover happens 8 months before TED/PED/PRD' do
            expect(handover_date).to eq(tariff_date - 8.months)
          end

          describe 'before handover date' do
            let(:today) { tariff_date - (8.months + 1.day) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { tariff_date - 8.months }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end
      end

      context 'when in a Womens prison' do
        let(:prison) { womens_prison }
        let(:arrival_date) { sentence_start_date }
        let(:today) { sentence_start_date + 1.week }

        context 'when before policy start date' do
          let(:sentence_start_date) { womens_policy_start_date - 1.day }

          it 'follows pre-policy rules' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
          end

          context 'when transferred to open conditions (Cat T)' do
            let(:category) { build(:offender_category, :female_open) }

            it 'follows pre-policy rules' do
              expect(pom).to be_supporting
              expect(com).to be_responsible
            end
          end
        end

        context 'when entering on or after the policy start date' do
          let(:sentence_start_date) { womens_policy_start_date }

          it 'follows POM policy rules' do
            expect(pom).to be_responsible
          end

          it 'follows COM policy rules' do
            expect(com).not_to be_involved
          end

          it 'gives reason "NPS Indeterminate"' do
            expect(reason).to eq("NPS Indeterminate")
          end

          context 'when transferred to open conditions (Cat T)' do
            let(:category) { build(:offender_category, :female_open, approvalDate: 3.days.ago) }

            it 'invokes open prison rules and COM is supporting' do
              expect(com).to be_supporting
              expect(pom).to be_responsible
            end

            it 'handover starts the day their category changed to "female open"' do
              expect(start_date).to eq(offender.category_active_since)
            end

            it 'handover happens 8 months before TED/PED/PRD' do
              expect(handover_date).to eq(tariff_date - 8.months)
            end

            it 'gives reason "NPS Indeterminate - Open conditions"' do
              expect(reason).to eq("NPS Indeterminate - Open conditions")
            end
          end
        end
      end

      context 'when in an open prison' do
        let(:prison) { open_prison }

        context 'when offender enters before the open prison policy start date' do
          let(:arrival_date) { open_policy_start_date - 1.day }

          it 'is COM responsible (pre-OMIC rules)' do
            expect(pom).to be_supporting
            expect(com).to be_responsible
            expect(start_date).to be_nil
            expect(handover_date).to be_nil
          end
        end

        context 'when offender enters on/after the open prison policy start date' do
          let(:arrival_date) { open_policy_start_date }

          it 'handover starts the day they arrive at the prison' do
            expect(start_date).to eq(offender.prison_arrival_date)
          end

          it 'handover happens 8 months before TED/PED/PRD' do
            expect(handover_date).to eq(tariff_date - 8.months)
          end

          it 'gives reason "NPS Indeterminate - Open conditions"' do
            expect(reason).to eq("NPS Indeterminate - Open conditions")
          end

          describe 'before handover date' do
            let(:today) { tariff_date - (8.months + 1.day) }

            it 'POM is responsible' do
              expect(pom).to be_responsible
            end

            it 'COM is supporting' do
              expect(com).to be_supporting
            end
          end

          describe 'on/after handover date' do
            let(:today) { tariff_date - 8.months }

            it 'POM is supporting' do
              expect(pom).to be_supporting
            end

            it 'COM is responsible' do
              expect(com).to be_responsible
            end
          end
        end
      end
    end
  end

  describe 'OMIC policy date boundaries' do
    let(:api_offender) do
      build(:hmpps_api_offender,
            prisonId: prison,
            sentence: attributes_for(:sentence_detail, :determinate, sentenceStartDate: sentence_start_date, conditionalReleaseDate: crd),
            category: offender_category
           ).tap do |o|
        o.prison_arrival_date = arrival_date
      end
    end

    let(:offender_category) { build(:offender_category, :cat_c) }

    let(:case_info) { build(:case_information, :english) }

    shared_examples 'pre-policy rules' do
      it 'is COM responsible' do
        expect(com).to be_responsible
        expect(pom).to be_supporting
      end

      it 'has no handover dates' do
        expect(start_date).to be_nil
        expect(handover_date).to be_nil
      end

      it 'has the expected reason' do
        expect(reason).to eq('Pre-OMIC rules')
      end
    end

    shared_examples 'OMIC policy rules' do
      it 'is POM responsible' do
        expect(pom).to be_responsible
        expect(com).not_to be_involved # until the handover start date
      end

      it 'has handover dates in the future' do
        expect(start_date).to be_future
        expect(handover_date).to be_future
      end

      it 'has the expected reason' do
        # The offender is stubbed as NPS without a MAPPA level
        expect(reason).to eq('NPS - MAPPA level unknown')
      end
    end

    context 'when sentenced before policy start and released before policy cutoff' do
      # Sentenced 1 day before policy start date
      let(:sentence_start_date) { HandoverDateService::ENGLISH_POLICY_START_DATE - 1.day } # 30 Sep 2019

      # Released 1 day before policy cutoff date
      let(:crd) { HandoverDateService::ENGLISH_PUBLIC_CUTOFF - 1.day } # 14 Feb 2021

      context 'when in a mens closed prison' do
        let(:prison) { closed_prison }

        it_behaves_like 'pre-policy rules'
      end

      context 'when in a mens open prison' do
        let(:prison) { open_prison }

        it_behaves_like 'pre-policy rules'
      end

      context 'when in a womens prison' do
        let(:prison) { womens_prison }

        # Sentenced 1 day before policy start date
        let(:sentence_start_date) { HandoverDateService::WOMENS_POLICY_START_DATE - 1.day } # 29 April 2021

        # Released 1 day before policy cutoff date
        let(:crd) { HandoverDateService::WOMENS_CUTOFF_DATE - 1.day } # 29 Sep 2022

        context 'when in closed conditions' do
          let(:offender_category) { build(:offender_category, :female_closed) }

          it_behaves_like 'pre-policy rules'
        end

        context 'when in open conditions' do
          let(:offender_category) { build(:offender_category, :female_open) }

          it_behaves_like 'pre-policy rules'
        end
      end
    end

    context 'when sentenced before policy start but released on/after policy cutoff' do
      # Sentenced 1 day before policy start date
      let(:sentence_start_date) { HandoverDateService::ENGLISH_POLICY_START_DATE - 1.day } # 30 Sep 2019

      # Released on/after the policy cutoff date
      let(:crd) { HandoverDateService::ENGLISH_PUBLIC_CUTOFF } # 15 Feb 2021

      # Set today's date to early on in the sentence (before the start of handover)
      let(:today) { sentence_start_date + 1.week }

      context 'when in a mens closed prison' do
        let(:prison) { closed_prison }

        it_behaves_like 'OMIC policy rules'
      end

      context 'when in a mens open prison' do
        let(:prison) { open_prison }

        context 'when arrived before open policy launched' do
          let(:arrival_date) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE - 1.day }

          it_behaves_like 'pre-policy rules'
        end

        context 'when arrived after open policy launched' do
          let(:arrival_date) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE + 1.day }

          it_behaves_like 'OMIC policy rules'
        end
      end

      context 'when in a womens prison' do
        let(:prison) { womens_prison }

        # Sentenced 1 day before policy start date
        let(:sentence_start_date) { HandoverDateService::WOMENS_POLICY_START_DATE - 1.day } # 29 Apr 2021

        # Released on/after the policy cutoff date
        let(:crd) { HandoverDateService::WOMENS_CUTOFF_DATE } # 30 Sep 2022

        context 'when in closed conditions' do
          let(:offender_category) { build(:offender_category, :female_closed) }

          it_behaves_like 'OMIC policy rules'
        end

        context 'when in open conditions' do
          let(:offender_category) { build(:offender_category, :female_open) }

          it_behaves_like 'OMIC policy rules'
        end
      end
    end

    context 'when sentenced after policy start date' do
      # Sentenced on/after policy start date
      let(:sentence_start_date) { HandoverDateService::ENGLISH_POLICY_START_DATE } # 1 Oct 2019

      # A release date some time in the future
      let(:crd) { 3.years.from_now }

      # Set today's date to early on in the sentence (before the start of handover)
      let(:today) { sentence_start_date + 1.week }

      context 'when in a mens closed prison' do
        let(:prison) { closed_prison }

        it_behaves_like 'OMIC policy rules'
      end

      context 'when in a mens open prison' do
        let(:prison) { open_prison }

        context 'when arrived before open policy launched' do
          let(:arrival_date) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE - 1.day }

          it_behaves_like 'pre-policy rules'
        end

        context 'when arrived after open policy launched' do
          let(:arrival_date) { HandoverDateService::OPEN_PRISON_POLICY_START_DATE + 1.day }

          it_behaves_like 'OMIC policy rules'
        end
      end

      context 'when in a womens prison' do
        let(:prison) { womens_prison }

        # Sentenced on/after policy start date
        let(:sentence_start_date) { HandoverDateService::WOMENS_POLICY_START_DATE } # 30 Apr 2021

        context 'when in closed conditions' do
          let(:offender_category) { build(:offender_category, :female_closed) }

          it_behaves_like 'OMIC policy rules'
        end

        context 'when in open conditions' do
          let(:offender_category) { build(:offender_category, :female_open) }

          it_behaves_like 'OMIC policy rules'
        end
      end
    end
  end

  context 'when offender is outside OMIC policy' do
    let(:api_offender) do
      build(:hmpps_api_offender,
            prisonId: prison,
            sentence: attributes_for(:sentence_detail, :civil_sentence)
           )
    end

    let(:case_info) { build(:case_information) }

    it 'raises an error' do
      expect { subject }.to raise_error(RuntimeError, "Offender #{offender.offender_no} falls outside of OMIC policy - cannot calculate handover dates")
    end
  end
end