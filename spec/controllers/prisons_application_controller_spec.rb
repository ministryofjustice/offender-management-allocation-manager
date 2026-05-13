require 'rails_helper'

RSpec.describe PrisonsApplicationController, type: :controller do
  describe 'before_actions' do
    it 'runs prison-specific setup in the declared order' do
      callbacks = described_class._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)

      expect(callbacks.index(:authenticate_user)).to be < callbacks.index(:check_active_caseload)
      expect(callbacks.index(:check_active_caseload)).to be < callbacks.index(:check_prison_access)
      expect(callbacks.index(:check_prison_access)).to be < callbacks.index(:load_staff_member)
      expect(callbacks.index(:load_staff_member)).to be < callbacks.index(:load_roles)
      expect(callbacks.index(:load_roles)).to be < callbacks.index(:service_notifications)
    end

    it 'captures PaperTrail controller info before prison-specific setup callbacks' do
      callbacks = described_class._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter)

      expect(callbacks.index(:set_paper_trail_controller_info)).to be < callbacks.index(:authenticate_user)
    end
  end

  describe '#info_for_paper_trail' do
    it 'uses session-backed actor names and the active prison id' do
      identity = instance_double(SsoIdentity, current_user_first_name: 'MOIC', current_user_last_name: 'POM')

      allow(controller).to receive(:sso_identity).and_return(identity)
      allow(controller).to receive(:active_prison_id).and_return('LEI')
      controller.instance_variable_set(:@current_user, Object.new)

      expect(controller.__send__(:info_for_paper_trail)).to eq(
        user_first_name: 'MOIC',
        user_last_name: 'POM',
        prison: 'LEI'
      )
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
