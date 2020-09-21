# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoveResponsibilityForm, type: :model do
  let(:case_information) { build(:case_information) }

  context 'without reason text' do
    subject { build(:remove_responsibility_form, nomis_offender_id: case_information.nomis_offender_id, reason_text: nil) }

    it 'is invalid with the correct error message' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(reason_text: ["You must say why you are changing responsibility for this case"])
    end
  end
end
