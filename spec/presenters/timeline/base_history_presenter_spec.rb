require 'rails_helper'

RSpec.describe Timeline::BaseHistoryPresenter do
  subject(:presenter) { presenter_class.new }

  let(:presenter_class) do
    Class.new(described_class) do
      def paper_trail_name_for(version)
        paper_trail_created_by_name(version)
      end

      def nomis_name_for(username)
        nomis_created_by_name(username)
      end

      def full_name_for(first_name, last_name)
        full_name(first_name, last_name)
      end

      def system_admin_name_for(version)
        system_admin_created_by_name(version)
      end
    end
  end

  describe '#paper_trail_created_by_name' do
    it 'returns the stored full name when both names are present' do
      version = PaperTrail::Version.new(user_first_name: 'Joe', user_last_name: 'Bloggs', whodunnit: 'jbloggs')

      expect(presenter.paper_trail_name_for(version)).to eq('Joe Bloggs')
    end

    it 'falls back to whodunnit when stored names are blank' do
      version = PaperTrail::Version.new(user_first_name: '', user_last_name: ' ', whodunnit: 'jbloggs')

      expect(presenter.paper_trail_name_for(version)).to eq('jbloggs')
    end

    it 'falls back to whodunnit when names are missing' do
      version = PaperTrail::Version.new(whodunnit: 'jbloggs')

      expect(presenter.paper_trail_name_for(version)).to eq('jbloggs')
    end
  end

  describe '#nomis_created_by_name' do
    it 'returns a full name from the NOMIS user details lookup' do
      allow(HmppsApi::NomisUserRolesApi).to receive(:user_details).with('joebloggs').and_return(
        instance_double(HmppsApi::UserDetails, first_name: 'Joe', last_name: 'Bloggs')
      )

      expect(presenter.nomis_name_for('joebloggs')).to eq('Joe Bloggs')
    end
  end

  describe '#full_name' do
    it 'returns a space-separated name' do
      expect(presenter.full_name_for('Joe', 'Bloggs')).to eq('Joe Bloggs')
    end
  end

  describe '#system_admin_created_by_name' do
    it 'returns the formatted system admin name when both note and whodunnit are present' do
      version = PaperTrail::Version.new(whodunnit: 'Test Admin', system_admin_note: 'For the following reasons')

      expect(presenter.system_admin_name_for(version)).to eq('System Admin (Test Admin)')
    end
  end
end
