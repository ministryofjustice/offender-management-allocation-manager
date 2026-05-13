# frozen_string_literal: true

require 'rails_helper'

feature 'Case History' do
  let(:probation_pom) do
    {
      primary_pom_nomis_id: 485_926,
      primary_pom_name: 'Pom, Moic',
      email: 'pom@digital.justice.gov.uk'
    }
  end

  let(:prison_pom) do
    {
      primary_pom_nomis_id: 485_833,
      primary_pom_name: 'Ricketts, Andrien',
      email: 'andrien.ricketts@digital.justice.gov.uk'
    }
  end

  let(:probation_pom_2) do
    {
      primary_pom_nomis_id: 485_637,
      primary_pom_name: 'Pobee-Norris, Kath',
      email: 'kath.pobee-norris@digital.justice.gov.uk'
    }
  end

  let(:pom_without_email) do
    {
      primary_pom_nomis_id: 485_636,
      primary_pom_name: "#{Faker::Name.last_name}, #{Faker::Name.first_name}"
    }
  end

  let(:spo) { build(:pom) }

  let(:nomis_offender) do
    build(:nomis_offender,
          prisonId: open_prison.code,
          sentence: attributes_for(:sentence_detail, :indeterminate, :welsh_open_policy))
  end
  let(:nomis_pentonville_offender) do
    build(:nomis_offender, prisonerNumber: nomis_offender.fetch(:prisonerNumber),
                           prisonId: second_prison.code,
                           sentence: attributes_for(:sentence_detail, :indeterminate, :welsh_open_policy))
  end
  let(:pontypool_ldu) do
    create(:local_delivery_unit, name: 'Pontypool LDU', email_address: 'pontypool-ldu@digital.justice.gov.uk')
  end
  let(:ci) { create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender.fetch(:prisonerNumber)), local_delivery_unit: pontypool_ldu) }
  let(:nomis_offender_id) { ci.nomis_offender_id }
  let!(:first_prison) { create(:prison) }
  let!(:second_prison) { create(:prison) }
  let!(:open_prison) { create(:prison, code: PrisonService::PRESCOED_CODE) }
  let(:offender_movements) do
    [
      attributes_for(:movement, toAgency: first_prison.code, movementDate: first_arrival_date - 1.day),
      attributes_for(:movement, toAgency: second_prison.code, movementDate: readmission_date),
      attributes_for(:movement, toAgency: open_prison.code, movementDate: transfer_date),
    ]
  end
  let(:today) { Time.zone.now } # try not to call Time.zone.now too often, to avoid 1-minute drifts
  let(:first_arrival_date) { today - 20.days }
  let(:deallocate_date) { today - 14.days }
  let(:readmission_date) { today - 10.days }
  let(:transfer_date) { today - 5.days }

  before do
    Timecop.travel Time.zone.local 2021, 2, 28, 11, 25, 35
  end

  after do
    Timecop.return
  end

  describe 'offender allocation history' do
    before do
      stub_offenders_for_prison(open_prison.code, [nomis_offender], offender_movements)
      stub_signin_spo spo, [open_prison.code]

      stub_pom build(:pom, staffId: probation_pom_2.fetch(:primary_pom_nomis_id))
      stub_pom_emails(probation_pom_2.fetch(:primary_pom_nomis_id), [probation_pom_2.fetch(:email)])

      stub_pom build(:pom, staffId: pom_without_email.fetch(:primary_pom_nomis_id))
      stub_pom_emails(pom_without_email.fetch(:primary_pom_nomis_id), [])

      stub_pom build(:pom, staffId: probation_pom.fetch(:primary_pom_nomis_id))
      stub_pom_emails(probation_pom.fetch(:primary_pom_nomis_id), [probation_pom.fetch(:email)])

      stub_pom build(:pom, staffId: prison_pom.fetch(:primary_pom_nomis_id))
      stub_pom_emails(prison_pom.fetch(:primary_pom_nomis_id), [prison_pom.fetch(:email)])

      stub_agencies(HmppsApi::PrisonApi::AgenciesApi::HOSPITAL_AGENCY_TYPE)
    end

    context 'when on the allocation history page' do
      before do
        # create a plausible timeline involving 3 prisons over a period of several days
        current_date = first_arrival_date
        allocation = Timecop.travel current_date do
          create(
            :allocation_history,
            prison: first_prison.code,
            event: AllocationHistory::ALLOCATE_PRIMARY_POM,
            event_trigger: AllocationHistory::USER,
            nomis_offender_id: nomis_offender_id,
            primary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
            primary_pom_name: probation_pom[:primary_pom_name],
            recommended_pom_type: 'prison',
            override_reasons: ["suitability"],
            suitability_detail: "Too high risk",
            primary_pom_allocated_at: current_date
          )
        end
        current_date += 1.day
        Timecop.travel current_date do
          allocation.update!(event: AllocationHistory::REALLOCATE_PRIMARY_POM,
                             event_trigger: AllocationHistory::USER,
                             primary_pom_nomis_id: probation_pom_2[:primary_pom_nomis_id],
                             primary_pom_name: probation_pom_2[:primary_pom_name],
                             recommended_pom_type: 'probation')
        end
        current_date += 1.day
        Timecop.travel current_date do
          allocation.update!(event: AllocationHistory::ALLOCATE_SECONDARY_POM,
                             secondary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
                             secondary_pom_name: probation_pom[:primary_pom_name])
        end
        current_date += 1.day
        Timecop.travel current_date do
          allocation.update!(event: AllocationHistory::DEALLOCATE_SECONDARY_POM,
                             secondary_pom_nomis_id: nil,
                             secondary_pom_name: nil)
        end
        # release offender (properly)
        Timecop.travel(deallocate_date) do
          MovementService.process_movement build(:movement, :release, offenderNo: allocation.nomis_offender_id)
        end
        # Now the offender is admitted to Pentonville having been released from Leeds earlier
        current_date = readmission_date
        Timecop.travel(current_date) do
          # offender got released - so have to re-create case information record
          # and re-find allocation record as it has been updated
          create(:case_information, :welsh, nomis_offender_id: nomis_offender_id, local_delivery_unit: pontypool_ldu)
          allocation = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id)
          allocation.update!(event: AllocationHistory::ALLOCATE_PRIMARY_POM,
                             event_trigger: AllocationHistory::USER,
                             prison: second_prison.code,
                             primary_pom_nomis_id: prison_pom[:primary_pom_nomis_id],
                             primary_pom_name: prison_pom[:primary_pom_name],
                             recommended_pom_type: 'prison')
        end

        current_date += 1.day
        Timecop.travel(current_date) do
          create(:early_allocation, offender: ci.offender, prison: second_prison.code, nomis_offender_id: nomis_offender_id)
          create :email_history, nomis_offender_id: nomis_offender_id,
                                 name: ci.local_delivery_unit.name,
                                 email: ci.local_delivery_unit.email_address,
                                 event: EmailHistory::AUTO_EARLY_ALLOCATION,
                                 prison: second_prison.code
        end

        current_date += 1.day
        Timecop.travel(current_date) do
          create(:early_allocation, :discretionary,
                 offender: ci.offender, prison: second_prison.code, nomis_offender_id: nomis_offender_id)
          create :email_history, nomis_offender_id: nomis_offender_id,
                                 name: ci.local_delivery_unit.name,
                                 email: ci.local_delivery_unit.email_address,
                                 event: EmailHistory::DISCRETIONARY_EARLY_ALLOCATION,
                                 prison: second_prison.code
        end

        current_date += 1.day
        Timecop.travel(current_date) do
          allocation.update!(event: AllocationHistory::REALLOCATE_PRIMARY_POM,
                             primary_pom_nomis_id: pom_without_email[:primary_pom_nomis_id],
                             primary_pom_name: pom_without_email[:primary_pom_name],
                             recommended_pom_type: 'probation')
          # Puy the offender in Pentonville to calculate handover dates
          # then put them back so that the transfer looks like it works
          stub_offender(nomis_pentonville_offender)
          perform_enqueued_jobs { RecalculateHandoverDateJob.perform_now nomis_offender_id }
          stub_offender(nomis_offender)
          stub_movements_for(nomis_offender_id, offender_movements)
        end

        Timecop.travel(transfer_date) do
          # create Email History for welsh offender transferring to Prescoed open prison by moving the prisoner
          MovementService.process_transfer build(:movement, :transfer, offenderNo: nomis_offender_id, toAgency: open_prison.code)
          perform_enqueued_jobs { RecalculateHandoverDateJob.perform_now nomis_offender_id }
        end
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)
      end

      let(:formatted_deallocate_date) { deallocate_date.strftime("#{deallocate_date.day.ordinalize} %B %Y (%R)") }
      let(:formatted_transfer_date) { "#{transfer_date.strftime("#{transfer_date.day.ordinalize} %B %Y")} (#{transfer_date.strftime('%R')})" }
      let(:allocation) { AllocationHistory.last }
      let(:history) { allocation.get_old_versions.append(allocation).sort_by!(&:updated_at).reverse! }
      let(:created_by_name) { allocation.get_old_versions.first.created_by_name }
      let(:last_history) { allocation.get_old_versions.first }

      it 'has the correct headings' do
        expect(page).to have_css('h1', text: "#{nomis_offender.fetch(:lastName)}, #{nomis_offender.fetch(:firstName)}")
      end

      it 'has 3 prison sections' do
        #  expect 3 'prison' sections - Prescoed, Pentonville and Leeds
        expect(all('.app-case-history__episode').size).to eq(3)
      end

      it 'has a section for Prescoed transfer to open conditions' do
        # 1st Prison - Prescoed. This only contains the transfer to open conditions
        within_timeline_section("Prescoed (HMP/YOI)") do
          expect(page).to have_css('.govuk-heading-m', text: "Prescoed (HMP/YOI)")

          prescoed_transfer = EmailHistory.where(nomis_offender_id: nomis_offender_id, event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION).first

          within_timeline_item(prescoed_transfer.email) do
            [
              ['.moj-timeline__title', "System generated email sent"],
              ['.moj-timeline__date', "#{prescoed_transfer.created_at.strftime("#{prescoed_transfer.created_at.day.ordinalize} %B %Y")} (#{prescoed_transfer.created_at.strftime('%R')}) email sent automatically"],
              ['.moj-timeline__description', "Request for supporting COM to be allocated after move to open prison sent to #{prescoed_transfer.email}"]
            ].each do |key, val|
              expect(page).to have_css(key, text: val)
            end
          end
        end
      end

      it 'has the transfer at the bottom of Presceod list' do
        expect(page).to have_css('.moj-timeline__title', text: "Prisoner unallocated")
      end

      it 'has a Pentonville section with the expected history entries' do
        within_timeline_section(second_prison.name) do
          expect(page).to have_css('.govuk-heading-m', text: second_prison.name)

          aggregate_failures do
            expect_timeline_titles('Prisoner reallocated', 'Prisoner allocated')
            expect(page).to have_css('.moj-timeline__header', text: 'Early allocation decision requested')
            expect(page).to have_css('.moj-timeline__header', text: 'Early allocation assessment form completed')
            expect(page).to have_css('.moj-timeline__header', text: 'System generated email sent')
          end
        end
      end

      it 'has a Pentonville section', :js do
        within_timeline_section(second_prison.name) do
          aggregate_failures do
            expect_timeline_titles('Prisoner reallocated', 'Prisoner allocated')
            expect(page).to have_css('.moj-timeline__header', text: 'Early allocation decision requested')
            expect(page).to have_css('.moj-timeline__header', text: 'Early allocation assessment form completed')
            expect(page).to have_css('.moj-timeline__header', text: 'System generated email sent')
          end
        end
      end

      it 'shows the case history', :js do
        hist_allocate_secondary = AllocationHistory.new secondary_pom_name: probation_pom[:primary_pom_name],
                                                        updated_at: first_arrival_date + 2.days,
                                                        created_by_name: created_by_name

        within_timeline_section(first_prison.name) do
          expect(page).to have_css('.govuk-heading-m', text: first_prison.name)

          within find_timeline_item("#{formatted_deallocate_date} by System Admin") { |item|
                   item.has_css?('.moj-timeline__title', text: 'Prisoner unallocated')
                 } do
            [
              ['.moj-timeline__title', "Prisoner unallocated"],
              ['.moj-timeline__date', "#{formatted_deallocate_date} by System Admin"],
            ].each do |key, val|
              expect(page).to have_css(key, text: val)
            end
          end

          within_timeline_item('Co-working unallocated') do
            [
              ['.moj-timeline__title', "Co-working unallocated"],
            ].each do |key, val|
              expect(page).to have_css(key, text: val)
            end
          end

          within_timeline_item('Co-working allocation') do
            [
              ['.moj-timeline__title', "Co-working allocation"],
              ['.moj-timeline__description', "Prisoner allocated to #{hist_allocate_secondary.secondary_pom_name.titleize} - #{probation_pom[:email]}"],
              ['.moj-timeline__date', "#{formatted_date_for(hist_allocate_secondary)} by #{hist_allocate_secondary.created_by_name}"],
            ].each do |key, val|
              expect(page).to have_css(key, text: val)
            end
          end

          expect_timeline_titles('Prisoner reallocated', 'Prisoner allocated')
        end
      end

      it 'links to previous Early Allocation assessments' do
        eligible_assessment = within_timeline_section(second_prison.name) do
          find_timeline_item('Early allocation assessment form completed') do |item|
            item.has_css?('.moj-timeline__description', text: 'Assessment outcome: eligible.')
          end
        end

        within eligible_assessment do
          expect(page).to have_css('.moj-timeline__title', text: 'Early allocation assessment form completed')
          expect(page).to have_link('View saved assessment')
          click_link 'View saved assessment'
        end

        # Assert that we're on the correct 'view' page
        target_early_allocation = EarlyAllocation.where(nomis_offender_id: nomis_offender_id).find(&:eligible?)
        view_assessment_page = prison_prisoner_early_allocation_path(open_prison.code, nomis_offender_id, target_early_allocation.id)
        expect(page).to have_current_path(view_assessment_page)
        expect(page).to have_content('Eligible')
        origin_url = page.current_path

        # Back link takes us back
        click_link 'Back'
        expect(page).to have_current_path(origin_url)
      end
    end
  end

  def formatted_date_for(history)
    "#{history.updated_at.strftime("#{history.updated_at.day.ordinalize} %B %Y")} (#{history.updated_at.strftime('%R')})"
  end

  context 'with a simple case' do
    before do
      stub_user('MOIC_POM', pom.staff_id)
      stub_offenders_for_prison(open_prison.code, [nomis_offender])
      stub_movements_for nomis_offender.fetch(:prisonerNumber), offender_movements
      signin_spo_user([open_prison.code])
      stub_poms(open_prison.code, [pom])
      stub_pom pom
    end

    let(:nomis_offender) { build(:nomis_offender, prisonId: open_prison.code) }
    let(:nomis_offender_id) { nomis_offender.fetch(:prisonerNumber) }
    let(:pom) { build(:pom) }
    let!(:case_info) do
      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
    end
    let!(:allocation) do
      create(:allocation_history, :primary, nomis_offender_id: nomis_offender_id, prison: first_prison.code,
                                            primary_pom_nomis_id: pom.staff_id)
    end

    context 'with a discretionary accepted early allocation' do
      before do
        create(:early_allocation, :discretionary_accepted,
               updated_by_firstname: 'Fred', updated_by_lastname: 'Bloggs',
               offender: case_info.offender, prison: second_prison.code, nomis_offender_id: nomis_offender_id)
      end

      it 'displays 3 sections - allocation plus 2 early allocation records' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        aggregate_failures do
          expect_timeline_titles(
            'Prisoner allocated',
            'Case information created',
            'Early allocation assessment form completed',
            'Early allocation decision recorded'
          )
        end
      end
    end

    context 'when VLO happens between allocation and de-allocation' do
      let(:tomorrow) { Time.zone.tomorrow }
      let(:day_after) { tomorrow + 1.day }

      before do
        Timecop.travel tomorrow do
          create(:victim_liaison_officer, offender: case_info.offender)
        end
        Timecop.travel day_after
        AllocationHistory.deallocate_primary_pom pom.staff_id, open_prison.code
      end

      after do
        Timecop.return
      end

      it 'displays the timeline without crashing' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)
      end
    end

    context 'when case information is added and later updated' do
      let(:tomorrow) { Time.zone.tomorrow }
      let(:day_after) { tomorrow + 1.day }
      let(:two_days_after) { day_after + 1.day }
      let!(:case_info) { nil }
      let!(:offender_record) { create(:offender, nomis_offender_id: nomis_offender_id) }

      before do
        Timecop.travel tomorrow do
          PaperTrail.request(
            whodunnit: 'legacy.user',
            controller_info: { user_first_name: 'Legacy', user_last_name: 'User', prison: open_prison.code }
          ) do
            create(
              :case_information,
              :manual_entry,
              offender: offender_record,
              tier: 'B',
              rosh_level: 'LOW',
              enhanced_resourcing: true
            )
          end
        end

        Timecop.travel day_after do
          CaseInformation.find_by!(nomis_offender_id: nomis_offender_id).update!(tier: 'C')
        end

        Timecop.travel two_days_after do
          PaperTrail.request(
            whodunnit: 'current.user',
            controller_info: { user_first_name: 'MOIC', user_last_name: 'POM', prison: open_prison.code }
          ) do
            CaseInformation.find_by!(nomis_offender_id: nomis_offender_id)
              .update!(rosh_level: 'VERY_HIGH', enhanced_resourcing: false)
          end
        end
      end

      it 'displays both manual and relevant system-generated case information history entries' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        aggregate_failures do
          expect_timeline_titles('Case information created', 'Case information updated')

          within(find_timeline_item('Case information created') { |item| item.text.include?('by Legacy User') }) do
            expect(page).to have_css('.moj-timeline__description', text: 'Tier: B')
            expect(page).to have_css('.moj-timeline__date', text: 'by Legacy User')
          end

          within(find_timeline_item('Case information updated') { |item| item.text.include?('by System Admin') }) do
            expect(page).to have_css('.moj-timeline__description', text: 'Tier: B → C')
            expect(page).to have_css('.moj-timeline__date', text: 'by System Admin')
          end

          within(find_timeline_item('Case information updated') { |item| item.text.include?('by MOIC POM') }) do
            expect(page).to have_css('.moj-timeline__description', text: 'Resourcing: enhanced → standard')
            expect(page).to have_css('.moj-timeline__date', text: 'by MOIC POM')
          end
        end
      end
    end

    context 'when case information is updated by the system' do
      let(:tomorrow) { Time.zone.tomorrow }

      before do
        Timecop.travel tomorrow do
          PaperTrail.request(whodunnit: nil, controller_info: {}) do
            case_info.update!(tier: 'B', rosh_level: 'LOW', enhanced_resourcing: true)
          end
        end
      end

      it 'shows the tracked case information changes as a system generated timeline entry' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        within_timeline_item('Case information updated') do
          aggregate_failures do
            expect(page).to have_css('.moj-timeline__description', text: 'ROSH: High → Low')
            expect(page).to have_css('.moj-timeline__date', text: 'by System Admin')
          end
        end
      end
    end

    context 'when case information is updated by the system and the rosh feature flag is disabled' do
      let(:tomorrow) { Time.zone.tomorrow }

      before do
        stub_feature_flag(:rosh_level, enabled: false)

        Timecop.travel tomorrow do
          PaperTrail.request(whodunnit: nil, controller_info: {}) do
            case_info.update!(tier: 'B', rosh_level: 'LOW', enhanced_resourcing: true)
          end
        end
      end

      it 'hides the ROSH change from the case history timeline entry' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        within_timeline_item('Case information updated') do
          aggregate_failures do
            expect(page).to have_no_css('.moj-timeline__description', text: 'ROSH: High → Low')
            expect(page).to have_css('.moj-timeline__description', text: 'Resourcing: standard → enhanced')
          end
        end
      end
    end

    context 'when case allocation decision is cleared by the system' do
      let(:tomorrow) { Time.zone.tomorrow }

      before do
        Timecop.travel tomorrow do
          PaperTrail.request(whodunnit: nil, controller_info: {}) do
            case_info.update!(enhanced_resourcing: nil)
          end
        end
      end

      it 'shows the tracked case information change to (unset)' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        within_timeline_item('Case information updated') do
          aggregate_failures do
            expect(page).to have_css('.moj-timeline__title', text: 'Case information updated')
            expect(page).to have_css('.moj-timeline__description', text: 'Resourcing: standard → (unset)')
            expect(page).to have_css('.moj-timeline__date', text: 'by System Admin')
          end
        end
      end
    end

    context 'when responsibility override is created and later removed' do
      let(:tomorrow) { Time.zone.tomorrow }
      let(:day_after) { tomorrow + 1.day }
      let(:responsibility_reason_text) { 'Because of local circumstances' }

      before do
        Timecop.travel tomorrow do
          PaperTrail.request(whodunnit: 'legacy.user') do
            create(
              :responsibility,
              offender: case_info.offender,
              nomis_offender_id: nomis_offender_id,
              reason: :other_reason,
              reason_text: responsibility_reason_text
            )
          end
        end

        Timecop.travel day_after do
          PaperTrail.request(
            whodunnit: 'current.user',
            controller_info: { user_first_name: 'MOIC', user_last_name: 'POM' }
          ) do
            Responsibility.find_by!(nomis_offender_id: nomis_offender_id).destroy!
          end
        end
      end

      it 'displays responsibility override history entries' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        expect(page).to have_css('.moj-timeline__title', text: 'Responsibility override added')
        expect(page).to have_css('.moj-timeline__description', text: 'Community probation team made responsible for this case')
        expect(page).to have_css('.moj-timeline__description', text: "Reason: Other – #{responsibility_reason_text}")
        expect(page).to have_css('.moj-timeline__title', text: 'Responsibility override removed')
        expect(page).to have_css('.moj-timeline__description', text: 'Community probation team no longer responsible for this case')
      end

      it 'renders historical and newly populated PaperTrail actor names together' do
        visit history_prison_prisoner_allocation_path(open_prison.code, nomis_offender_id)

        expect(page).to have_css('.moj-timeline__date', text: 'by legacy.user')
        expect(page).to have_css('.moj-timeline__date', text: 'by MOIC POM')
      end
    end
  end
end
