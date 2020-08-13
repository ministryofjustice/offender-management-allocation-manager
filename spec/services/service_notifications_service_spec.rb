require 'rails_helper'

describe ServiceNotificationsService do
  describe 'notifications' do
    let(:pom_role) { ['POM'] }
    let(:spo_role) { ['SPO'] }
    let(:both_roles) { %w(SPO POM) }


    it 'returns an empty array when file is empty' do
      stub_const("ServiceNotifications::Yaml::Data", '')
      expect(described_class.notifications(pom_role)).to eq([])
    end

    it 'returns an empty array when YAML file does not return an array' do
      stub_const("ServiceNotifications::Yaml::Data", '{"notifications"=>nil}')
      expect(described_class.notifications(both_roles)).to eq([])
    end

    it 'returns an empty array when user has no roles' do
      roles = []
      start_date = 2.days.ago.strftime("%d/%m/%Y")
      data =
        {
          "notifications" => [
            {
              "id" => "my-new-feature",
              "start_date" => start_date,
              "role" => ["POM"],
              "end_date" => Time.zone.now.to_date,
              "text" => "This is a test banner"
            }
          ]
        }

      stub_const("ServiceNotifications::Yaml::Data", data)
      expect(described_class.notifications(roles)).to eq([])
    end

    it 'returns an empty array when there are no notifications that match the users role' do
      start_date = 4.days.ago.strftime("%d/%m/%Y")
      data =
        {
          "notifications" => [
            {
              "id" => "my-new-feature",
              "start_date" => start_date,
              "role" => ["POM"],
              "end_date" => Time.zone.now.to_date,
              "text" => "This is a test banner"
            }
          ]
        }

      stub_const("ServiceNotifications::Yaml::Data", data)
      expect(described_class.notifications(spo_role)).to eq([])
    end

    it 'returns an empty array when there are no notifications for today' do
      start_date = 2.months.ago.strftime("%d/%m/%Y")
      end_date = 1.day.ago.strftime("%d/%m/%Y")
      data =
        {
          "notifications" => [
            {
              "id" => "my-new-feature",
              "start_date" => start_date,
              "role" => ["POM"],
              "end_date" => end_date,
              "text" => "This is a test banner"
            }
          ]
        }

      stub_const("ServiceNotifications::Yaml::Data", data)
      expect(described_class.notifications(pom_role)).to eq([])
    end

    it 'returns notifications when there are roles matching the user roles that should be shown today' do
      start_dates = [
        3.days.ago.strftime("%d/%m/%Y"),
        1.day.ago.strftime("%d/%m/%Y"),
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
              "end_date" => 11.days.from_now.strftime("%d/%m/%Y"), #active
              "text" => "New SPO feature"
            },
            {
              "id" => "new-spo-feature",
              "start_date" => start_dates[1],
              "role" => ["SPO", "POM"],
              "end_date" => Time.zone.now.to_date.strftime("%d/%m/%Y"), #active - today is the last day
              "text" => "New SPO feature"
            },
            {
              "id" => "new-app-feature",
              "start_date" => start_dates[2],
              "role" => ["POM", "SPO"],
              "end_date" => 16.days.from_now.strftime("%d/%m/%Y"), #active
              "text" => "New design layout"
            },
            {
              "id" => "recently-ended-feature",
              "start_date" => start_dates[2],
              "role" => ["POM", "SPO"],
              "end_date" => 1.day.ago.strftime("%d/%m/%Y"), #inactive - ended yesterday
              "text" => "An old feature"
            },
            {
              "id" => "old-feature",
              "start_date" => start_dates.last,
              "role" => ["POM", "SPO"],
              "end_date" => 4.months.ago.strftime("%d/%m/%Y"), #inactive
              "text" => "An old feature"
            }
          ]
        }

      stub_const("ServiceNotifications::Yaml::Data", data)
      expect(described_class.notifications(both_roles)).to eq(data['notifications'].take(3))
    end
  end
end
