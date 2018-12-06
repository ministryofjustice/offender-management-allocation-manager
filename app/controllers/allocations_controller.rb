class AllocationsController < ApplicationController
  before_action :authenticate_user

  # rubocop:disable Metrics/MethodLength
  def index
    @prisoners = [
      {
        id: 1,
        name: 'Toohey, Briano',
        number: 'A14GHJFD',
        arrival_date: '18/06/2018',
        release_date: '16/06/2054'
      },
      {
        id: 2,
        name: 'Smith, Frank',
        number: 'X14HHJFD',
        arrival_date: '18/04/2017',
        release_date: '16/06/2030'
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength
end
