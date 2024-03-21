# frozen_string_literal: true

class InfoController < ApplicationController
  def index
    render json: {
      git: {
        branch: ENV['GIT_BRANCH']
      },
      build: {
        artifact: 'offender-management-allocation-manager',
        version: ENV['BUILD_NUMBER'],
        name: 'offender-management-allocation-manager'
      },
      productId: ENV['PRODUCT_ID']
    }
  end
end
