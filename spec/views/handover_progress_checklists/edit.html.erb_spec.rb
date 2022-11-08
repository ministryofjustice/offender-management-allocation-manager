RSpec.describe 'handover_progress_checklists/edit' do
  let(:prison_code) { 'PRI' }
  let(:prison) { instance_double Prison, code: prison_code }
  let(:nomis_offender_id) { FactoryBot.generate(:nomis_offender_id) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:prison, prison)
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
