RSpec.describe 'handover_progress_checklists/edit' do
  let(:prison_code) { 'PRI' }
  let(:prison) { instance_double Prison, code: prison_code }
  let(:nomis_offender_id) { FactoryBot.generate(:nomis_offender_id) }
  let(:offender) do
    stub_mpc_offender(
      offender_no: nomis_offender_id,
      com_responsible_date: Date.new(2022, 11, 1),
      first_name: 'OFFENDERFIRSTNAME',
      full_name_ordered: 'Offenderfirstname Offenderlastname',
      date_of_birth: Date.new(1993, 2, 20),
      allocated_com_name: 'Comfirstname Comlastname',
      allocated_com_email: 'comfirstname.comlastname@example.com')
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    offender # instantiate and stub

    assign(:prison, prison)
    assign(:offender, offender)
  end

  describe 'in the usual case, when all items are unfinished' do
    before do
      assign(:handover_progress_checklist, HandoverProgressChecklist.new(
                                             nomis_offender_id: nomis_offender_id,
                                             reviewed_oasys: false,
                                             contacted_com: false,
                                             attended_handover_meeting: false))
      render
    end

    it 'renders all checkboxes unticked' do
      aggregate_failures do
        expect(page).not_to have_css('input[name="handover_progress_checklist[reviewed_oasys]"][checked=checked]')

        expect(page).not_to have_css('input[name="handover_progress_checklist[contacted_com]"][checked=checked]',
                                     visible: false)

        expect(page).not_to have_css('input[name="handover_progress_checklist[attended_handover_meeting]"]' \
                                     '[checked=checked]',
                                     visible: false)
      end
    end

    it 'shows offender data' do
      aggregate_failures do
        expect(page).to have_content 'Record handover progress for Offenderfirstname'
        # expect(page).to have_content '0 of 3 tasks'
        expect(page).to have_content 'Name: Offenderfirstname Offenderlastname'
        expect(page).to have_content 'COM responsible from 01 Nov 2022'
        expect(page).to have_content 'Date of birth: 20 Feb 1993'
        expect(page).to have_content "Prison number: #{nomis_offender_id}"
        expect(page).to have_content 'COM name: Comfirstname Comlastname'
        expect(page).to have_content 'COM email: comfirstname.comlastname@example.com'
        expect(page).to have_content 'COM responsible from 01 Nov 2022'
      end
    end
  end

  describe 'when all items are completed' do
    before do
      assign(:handover_progress_checklist, HandoverProgressChecklist.new(
                                             nomis_offender_id: nomis_offender_id,
                                             reviewed_oasys: true,
                                             contacted_com: true,
                                             attended_handover_meeting: true))
      render
    end

    it 'shows offender data different from the usual case' do
      # expect(page).to have_content '3 of 3 tasks'
    end

    it 'renders checkboxes correctly' do
      aggregate_failures do
        expect(page).to have_css('input[name="handover_progress_checklist[reviewed_oasys]"][checked=checked]',
                                 visible: false)

        expect(page).to have_css('input[name="handover_progress_checklist[contacted_com]"][checked=checked]',
                                 visible: false)

        expect(page).to have_css('input[name="handover_progress_checklist[attended_handover_meeting]"][checked=checked]',
                                 visible: false)
      end
    end
  end
end
