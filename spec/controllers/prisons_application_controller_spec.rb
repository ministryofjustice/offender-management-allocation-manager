require 'rails_helper'

RSpec.describe PrisonsApplicationController, type: :controller do
  describe 'before_actions' do
    it 'checks the active caseload before prison-specific setup' do
      callbacks = described_class._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)

      expect(callbacks.index(:authenticate_user)).to be < callbacks.index(:check_active_caseload)
      expect(callbacks.index(:check_active_caseload)).to be < callbacks.index(:check_prison_access)
      expect(callbacks.index(:check_active_caseload)).to be < callbacks.index(:load_staff_member)
    end
  end

  describe 'referrer' do
    context 'when referrer is set to null' do
      it 'redirects to the root_path of /' do
        allow(request).to receive(:referer).and_return(nil)

        expect(subject.__send__(:referrer)).to eq('/')
      end
    end

    context 'when the referrer is not null' do
      it 'sets the referrer to the non-null path' do
        allow(request).to receive(:referer).and_return('/fred')

        expect(subject.__send__(:referrer)).to eq('/fred')
      end
    end
  end
end
