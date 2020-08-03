require 'rails_helper'

describe ServiceNotificationsService do
  describe 'notifications' do
    let(:pom_role) { ['POM'] }
    let(:spo_role) { ['SPO'] }
    let(:both_roles) { %w(SPO POM) }
    let(:filename) { 'app/notifications/service_notifications.yaml' }

    it 'returns an empty array if file is empty' do
      allow(YAML).to receive(:load).with(File.read(filename)).and_return('')
      expect(described_class.notifications(pom_role)).to eq([])
    end

    it 'returns an empty array if YAML does not return an array' do
      allow(YAML).to receive(:load).with(File.read(filename)).and_return('{"notifications"=>nil}')
      expect(described_class.notifications(both_roles)).to eq([])
    end

    it 'returns an empty array if there are no roles' do
      roles = []
      start_date = 2.days.ago.strftime("%d/%m/%Y")
      data =
        {
          "notifications" => [
            {
              "id" => "my-new-feature",
              "start_date" => start_date,
              "role" => ["POM"],
              "duration" => 14,
              "text" => "This is a test banner"
            }
          ]
        }

      allow(YAML).to receive(:load).with(File.read(filename)).and_return(data)
      expect(described_class.notifications(roles)).to eq([])
    end

    it 'returns an empty array if there are no notifications that match the users role' do
      start_date = 4.days.ago.strftime("%d/%m/%Y")
      data =
        {
          "notifications" => [
            {
              "id" => "my-new-feature",
              "start_date" => start_date,
              "role" => ["POM"],
              "duration" => 14,
              "text" => "This is a test banner"
            }
          ]
        }

      allow(YAML).to receive(:load).with(File.read(filename)).and_return(data)
      expect(described_class.notifications(spo_role)).to eq([])
    end

    it 'returns an empty array if there are no notifications for today' do
      start_date = 2.months.ago.strftime("%d/%m/%Y")
      data =
        {
          "notifications" => [
            {
              "id" => "my-new-feature",
              "start_date" => start_date,
              "role" => ["POM"],
              "duration" => 30,
              "text" => "This is a test banner"
            }
          ]
        }

      allow(YAML).to receive(:load).with(File.read(filename)).and_return(data)
      expect(described_class.notifications(pom_role)).to eq([])
    end

    it 'returns notifications for roles that should be shown today' do
      start_dates = [
        3.days.ago.strftime("%d/%m/%Y"),
        2.weeks.ago.strftime("%d/%m/%Y"),
        5.months.ago.strftime("%d/%m/%Y")
      ]
      data =
        {
          "notifications" => [
            {
              "id" => "new-spo-feature",
              "start_date" => start_dates.first,
              "role" => ["SPO"],
              "duration" => 14,
              "text" => "New SPO feature"
            },
            {
              "id" => "new-app-feature",
              "start_date" => start_dates[1],
              "role" => ["POM", "SPO"],
              "duration" => 30,
              "text" => "New design layout"
            },
            {
              "id" => "old-feature",
              "start_date" => start_dates.last,
              "role" => ["POM", "SPO"],
              "duration" => 30,
              "text" => "An old feature"
            }
          ]
        }

      allow(YAML).to receive(:load).with(File.read(filename)).and_return(data)
      expect(described_class.notifications(both_roles)).to eq(data['notifications'].take(2))
    end
  end
end
