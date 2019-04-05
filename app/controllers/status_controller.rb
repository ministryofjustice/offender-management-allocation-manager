# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    render(
      json: {
        'status' => 'ok',
        'postgresVersion' => postgres_version
      }
    )
  end

private

  def postgres_version
    @postgres_version ||= ActiveRecord::Base.connection.select_value('SELECT version()')
  end
end
