require 'rails_helper'

feature 'Allocation History' do
  let!(:probation_pom) do
    {
      primary_pom_nomis_id: 485_926,
      primary_pom_name: 'Pom, Moic',
      email: 'pom@digital.justice.gov.uk'
    }
  end

  let!(:prison_pom) do
    {
      primary_pom_nomis_id: 485_833,
      primary_pom_name: 'Ricketts, Andrien',
      email: 'andrien.ricketts@digital.justice.gov.uk'
    }
  end

  let!(:probation_pom_2) do
    {
      primary_pom_nomis_id: 485_637,
      primary_pom_name: 'Pobee-Norris, Kath',
      email: 'kath.pobee-norris@digital.justice.gov.uk'
    }
  end

  let!(:pom_without_email) do
    {
      primary_pom_nomis_id: 485_636,
      primary_pom_name: "#{Faker::Name.last_name}, #{Faker::Name.first_name}"
    }
  end

  let(:ci) { create(:case_information, nomis_offender_id: 'G4273GI') }
  let(:nomis_offender_id) { ci.nomis_offender_id }

  describe 'offender allocation history', vcr: { cassette_name: :offender_allocation_history } do
    shared_context 'when on the allocation history page' do
      before do
        allocation = create(
          :allocation,
          nomis_offender_id: nomis_offender_id,
          primary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
          primary_pom_name: probation_pom[:primary_pom_name],
          recommended_pom_type: 'prison',
          override_reasons: ["suitability"],
          suitability_detail: "Too high risk",
          created_at: Time.zone.now - 10.days,
          updated_at: Time.zone.now - 10.days,
          primary_pom_allocated_at: Time.zone.now - 12.days
        )
        allocation.update!(event: Allocation::REALLOCATE_PRIMARY_POM,
                           primary_pom_nomis_id: probation_pom_2[:primary_pom_nomis_id],
                           primary_pom_name: probation_pom_2[:primary_pom_name],
                           recommended_pom_type: 'probation',
                           updated_at: Time.zone.now - 10.days
        )
        allocation.update!(event: Allocation::ALLOCATE_SECONDARY_POM,
                           secondary_pom_nomis_id: probation_pom[:primary_pom_nomis_id],
                           secondary_pom_name: probation_pom[:primary_pom_name],
                           updated_at: Time.zone.now - 8.days
        )
        allocation.update!(event: Allocation::DEALLOCATE_SECONDARY_POM,
                           secondary_pom_nomis_id: nil,
                           secondary_pom_name: nil,
                           recommended_pom_type: nil,
                           updated_at: Time.zone.now - 7.days
        )
        Timecop.travel(deallocate_date) do
          allocation.dealloate_offender_after_transfer
        end
        Timecop.travel(Time.zone.now - 5.days) do
          allocation.update!(event: Allocation::ALLOCATE_PRIMARY_POM,
                             prison: 'PVI',
                             primary_pom_nomis_id: prison_pom[:primary_pom_nomis_id],
                             primary_pom_name: prison_pom[:primary_pom_name],
                             recommended_pom_type: 'prison',
                             created_by_name: nil)
        end

        Timecop.travel(Time.zone.now - 4.days) do
          create(:early_allocation, case_information: ci, prison: 'PVI', nomis_offender_id: nomis_offender_id)
          create :email_history, nomis_offender_id: nomis_offender_id,
                 name: ci.team.local_divisional_unit.name,
                 email: ci.team.local_divisional_unit.email_address,
                 event: EmailHistory::AUTO_EARLY_ALLOCATION,
                 prison: 'PVI'
        end

        Timecop.travel(Time.zone.now - 3.days) do
          create(:early_allocation, :discretionary, case_information: ci, prison: 'PVI', nomis_offender_id: nomis_offender_id)
          create :email_history, nomis_offender_id: nomis_offender_id,
                 name: ci.team.local_divisional_unit.name,
                 email: ci.team.local_divisional_unit.email_address,
                 event: EmailHistory::DISCRETIONARY_EARLY_ALLOCATION,
                 prison: 'PVI'
        end

        Timecop.travel(Time.zone.now - 2.days) do
          allocation.update!(event: Allocation::REALLOCATE_PRIMARY_POM,
                             primary_pom_nomis_id: pom_without_email[:primary_pom_nomis_id],
                             primary_pom_name: pom_without_email[:primary_pom_name],
                             recommended_pom_type: 'probation')
        end

        Timecop.travel(transfer_date) do
          allocation.dealloate_offender_after_transfer
        end

        Timecop.travel(Time.zone.now - 3.weeks) do
          # create Email History for welsh offender transferring to Prescoed open prison
          create :email_history, nomis_offender_id: nomis_offender_id,
                 name: 'Pontypool LDU',
                 email: 'pontypool-ldu@digital.justice.gov.uk',
                 event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION,
                 prison: PrisonService::PRESCOED_CODE
        end
        visit prison_allocation_history_path('LEI', nomis_offender_id)
      end

      let(:deallocate_date) { Time.zone.now - 6.days }
      let(:formatted_deallocate_date) { deallocate_date.strftime("#{deallocate_date.day.ordinalize} %B %Y") }
      let(:transfer_date) { Time.zone.now - 1.day }
      let(:formatted_transfer_date) { transfer_date.strftime("#{transfer_date.day.ordinalize} %B %Y") + " (" + transfer_date.strftime("%R") + ")" }
      let(:allocation) { Allocation.last }
      let(:history) { allocation.get_old_versions.append(allocation).sort_by!(&:updated_at).reverse! }

      it 'shows the case history' do
        history1 = history[1]
        history2 = history[2]
        hist_allocate_secondary = history[5]
        history6 = history[6]
        prescoed_transfer = EmailHistory.where(nomis_offender_id: nomis_offender_id, event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION).first

        [
          ['h1', "Abbella, Ozullirn"],
          ['.govuk-heading-m', "HMP Pentonville"],
          ['.moj-timeline__title', "Prisoner unallocated (transfer)"],
          ['.moj-timeline__date', formatted_transfer_date.to_s],
          ['.moj-timeline__title', "Prisoner reallocated"],
          ['.moj-timeline__description', "Prisoner reallocated to #{history1.primary_pom_name.titleize} - (email address not found) Tier: #{history1.allocated_at_tier}"],
          ['.moj-timeline__date', formatted_date_for(history1).to_s],
          ['.moj-timeline__title', "Prisoner allocated"],
          ['.moj-timeline__description', "Prisoner allocated to #{history2.primary_pom_name.titleize} - #{prison_pom[:email]} Tier: #{history2.allocated_at_tier}"],
          ['.moj-timeline__date', formatted_date_for(history2).to_s],
          ['.moj-timeline__description', "Prisoner allocated to #{hist_allocate_secondary.secondary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{hist_allocate_secondary.allocated_at_tier}"],
          ['.moj-timeline__date', "#{formatted_date_for(hist_allocate_secondary)} by #{hist_allocate_secondary.created_by_name.titleize}"],
          ['.govuk-heading-m', "HMP Leeds"],
          ['.moj-timeline__title', "Prisoner unallocated"],
          ['.moj-timeline__title', "Co-working unallocated"],
          ['.moj-timeline__date', formatted_deallocate_date.to_s],
          ['.moj-timeline__title', "Prisoner reallocated"],
          ['.moj-timeline__description', "Prisoner reallocated to #{history6.primary_pom_name.titleize} - #{probation_pom_2[:email]} Tier: #{history6.allocated_at_tier}"],
          ['.moj-timeline__date', "#{formatted_date_for(history6)} by #{history6.created_by_name.titleize}"],
          ['.moj-timeline__title', "Prisoner allocated"],
          ['.moj-timeline__description', "Prisoner allocated to #{history.last.primary_pom_name.titleize} - #{probation_pom[:email]} Tier: #{history.last.allocated_at_tier}"],
          ['.moj-timeline__description', "Probation POM allocated instead of recommended Prison POM", "Reason(s):", "- Prisoner assessed as suitable for a prison POM despite tiering calculation", "Too high risk"],
          ['.moj-timeline__date', "#{formatted_date_for(history.last)} by #{history.last.created_by_name.titleize}"],
          ['.govuk-heading-m', "HMP/YOI Prescoed"],
          ['.moj-timeline__title', "Offender transferred to an open prison"],
          ['.moj-timeline__date', "#{prescoed_transfer.created_at.strftime("#{prescoed_transfer.created_at.day.ordinalize} %B %Y")} (#{prescoed_transfer.created_at.strftime('%R')}) email sent automatically"],
          ['.moj-timeline__description', "The LDU for #{prescoed_transfer.name} - #{prescoed_transfer.email} - was sent an email asking them to appoint a Supporting COM."]].each do |key, val|
          expect(page).to have_css(key, text: val)
        end
      end

      it 'links to previous Early Allocation assessments' do
        # The 6th history item is an 'eligible' early allocation assessment
        eligible_assessment = page.find('.moj-timeline > .moj-timeline__item:nth-child(6)')

        within eligible_assessment do
          expect(page).to have_css('.moj-timeline__title', text: 'Early allocation assessment form completed')
          expect(page).to have_link('View saved assessment')
          click_link 'View saved assessment'
        end

        # Assert that we're on the correct 'view' page
        target_early_allocation = EarlyAllocation.where(nomis_offender_id: nomis_offender_id).find(&:eligible?)
        view_assessment_page = prison_prisoner_early_allocation_path('LEI', nomis_offender_id, target_early_allocation.id)
        expect(page).to have_current_path(view_assessment_page)
        expect(page).to have_content('Eligible')

        # Back link takes us back
        click_link 'Back'
        case_history_page = prison_allocation_history_path('LEI', nomis_offender_id)
        expect(page).to have_current_path(case_history_page)
      end
    end

    context 'when logged in as an SPO' do
      before { signin_spo_user }

      include_context 'when on the allocation history page'
    end

    context 'when logged in as a POM' do
      before { signin_pom_user }

      include_context 'when on the allocation history page'
    end
  end

  def formatted_date_for(history)
    history.updated_at.strftime("#{history.updated_at.day.ordinalize} %B %Y") + " (" + history.updated_at.strftime("%R") + ")"
  end

  context 'when prisoner has been released' do
    let(:nomis_offender) { build(:nomis_offender) }
    let(:nomis_offender_id) { nomis_offender.fetch(:offenderNo) }
    let(:prison) { build(:prison).code }
    let(:pom) { build(:pom) }

    before do
      stub_auth_token
      stub_user(username: 'MOIC_POM', staff_id: pom.staff_id)
      stub_offender(nomis_offender)
      stub_offenders_for_prison(prison, [nomis_offender])
      signin_spo_user([prison])
      stub_poms(prison, [pom])
      stub_pom pom
      create(:case_information, nomis_offender_id: nomis_offender_id)
      allocation = create(:allocation, :primary, nomis_offender_id: nomis_offender_id, prison: prison, primary_pom_nomis_id: pom.staff_id)
      allocation.deallocate_offender_after_release
    end

    scenario 'visit allocation history page' do
      visit prison_allocation_history_path(prison, nomis_offender_id)
      expect(page).to have_content("Prisoner released")
    end
  end
end
