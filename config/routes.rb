Rails.application.routes.draw do
  root to: 'dashboard#index'

  match "/401", :to => "errors#unauthorized", :via => :all
  match "/404", :to => "errors#not_found", :via => :all, constraints: lambda { |req| req.format == :html }
  match "/500", :to => "errors#internal_server_error", :via => :all
  match "/503", :to => "errors#internal_server_error", :via => :all

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'
  get('/prisoners/:id' => 'prisoners#show', as: 'prisoner_show')
  get('/prisoners/:id/image.jpg' => 'prisoners#image', as: 'prisoner_image')

  get('/allocations/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocations#confirm', as: 'confirm_allocation')
  get('/summary' => 'summary#index')
  get('/summary/allocated' => 'summary#allocated')
  get('/summary/unallocated' => 'summary#unallocated')
  get('/summary/pending' => 'summary#pending')

  get('/search' => 'search#search')

  get('/prisons' => 'prisons#index')
  get('/prisons/update' => 'prisons#set_active')

  resources :caseload, only: %i[ index new ], controller: 'caseload'
  resources :health, only: %i[ index ], controller: 'health'
  resources :status, only: %i[ index ], controller: 'status'
  resource :overrides,  only: %i[ new create ], path_names: { new: 'new/:nomis_offender_id/:nomis_staff_id'}
  resources :poms, only: %i[ index show edit update ], param: :nomis_staff_id
  resources :allocations, only: %i[ show new create edit ], param: :nomis_offender_id, path_names: {
    new: ':nomis_offender_id/new',
  }
  resource :case_information, only: %i[new create edit update], controller: 'case_information', path_names: {
      new: 'new/:nomis_offender_id',
      edit: 'edit/:nomis_offender_id'
  }

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # TODO: Re-enable this engine for managing features when we have proper roles for admins
  # mount Flipflop::Engine => "/flipflop"
end
