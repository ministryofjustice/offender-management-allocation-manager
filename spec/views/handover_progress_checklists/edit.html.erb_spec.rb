RSpec.describe 'handover_progress_checklists/edit' do
  let(:prison_code) { 'PRI' }
  let(:prison) { instance_double Prison, code: prison_code }
  let(:nomis_offender_id) { FactoryBot.generate(:nomis_offender_id) }
  let(:offender) do
    stub_mpc_offender(
      offender_no: nomis_offender_id,
      model: double(handover_date: Date.new(2022, 11, 1)),
      first_name: 'OFFENDERFIRSTNAME',
      full_name_ordered: 'Offenderfirstname Offenderlastname',
      date_of_birth: Date.new(1993, 2, 20),
      allocated_com_name: 'Comfirstname Comlastname',
      allocated_com_email: 'comfirstname.comlastname@example.com')
  end
  let(:handover_progress_checklist) do
    # Use model and not instance_double because form_for expects all kinds of crap that we can't be bothered to mock
    model = HandoverProgressChecklist.new(
      nomis_offender_id: nomis_offender_id,
      reviewed_oasys: false,
      contacted_com: false,
      sent_handover_report: false)
    allow(model).to receive_messages(handover_type: 'enhanced')
    model
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    offender # instantiate and stub

    assign(:prison, prison)
    assign(:prison_id, prison_code)
    assign(:offender, offender)
    assign(:handover_progress_checklist, handover_progress_checklist)
  end

  describe 'when all items are incomplete' do
    before do
      render
    end

    it 'renders all checkboxes unticked' do
      aggregate_failures do
        expect(page).not_to have_css('input[name="handover_progress_checklist[reviewed_oasys]"][checked=checked]',
                                     visible: :all)

        expect(page).not_to have_css('input[name="handover_progress_checklist[contacted_com]"][checked=checked]',
                                     visible: :all)

        expect(page).not_to have_css('input[name="handover_progress_checklist[sent_handover_report]"]' \
                                     '[checked=checked]',
                                     visible: :all)
      end
    end

    it 'shows offender data' do
      aggregate_failures do
        expect(page).to have_content 'Record handover progress for Offenderfirstname', normalize_ws: true
        expect(page).to have_content '0 of 3 tasks', normalize_ws: true
        expect(page).to have_content 'Name: Offenderfirstname Offenderlastname', normalize_ws: true
        expect(page).to have_content 'COM responsible from 01 Nov 2022', normalize_ws: true
        expect(page).to have_content 'Date of birth: 20 Feb 1993', normalize_ws: true
        expect(page).to have_content "Prison number: #{nomis_offender_id}", normalize_ws: true
        expect(page).to have_content 'COM name: Comfirstname Comlastname', normalize_ws: true
        expect(page).to have_content 'COM email: comfirstname.comlastname@example.com', normalize_ws: true
        expect(page).to have_content 'COM responsible from 01 Nov 2022', normalize_ws: true
      end
    end
  end

  describe 'when all items are completed' do
    before do
      handover_progress_checklist.attributes = {
        reviewed_oasys: true,
        contacted_com: true,
        attended_handover_meeting: true,
      }
      render
    end

    it 'shows offender data that depends on task completion' do
      aggregate_failures do
        expect(page).to have_content '3 of 3 tasks', normalize_ws: true
      end
    end

    it 'renders checkboxes correctly' do
      aggregate_failures do
        expect(page).to have_css('input[name="handover_progress_checklist[reviewed_oasys]"][checked=checked]',
                                 visible: :all)

        expect(page).to have_css('input[name="handover_progress_checklist[contacted_com]"][checked=checked]',
                                 visible: :all)

        expect(page).to have_css('input[name="handover_progress_checklist[attended_handover_meeting]"][checked=checked]',
                                 visible: :all)
      end
    end
  end

  describe 'when case type is CRC' do
    before do
      allow(handover_progress_checklist).to receive_messages(handover_type: 'standard')
      render
    end

    it 'only renders 2 checkboxes' do
      aggregate_failures do
        expect(page).to have_css('input[name="handover_progress_checklist[contacted_com]"]',
                                 visible: :all)

        expect(page).to have_css('input[name="handover_progress_checklist[sent_handover_report]"]',
                                 visible: :all)
      end
    end

    it 'does not render reviewed_oasys checkbox' do
      expect(page).not_to have_css('input[name="handover_progress_checklist[reviewed_oasys]"]',
                                   visible: :all)
    end
  end
end
