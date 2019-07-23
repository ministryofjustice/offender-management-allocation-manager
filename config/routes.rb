Rails.application.routes.draw do
  root to: 'root#index'

  match "/401", :to => "errors#unauthorized", :via => :all
  match "/404", :to => "errors#not_found", :via => :all, constraints: lambda { |req| req.format == :html }
  match "/500", :to => "errors#internal_server_error", :via => :all
  match "/503", :to => "errors#internal_server_error", :via => :all

  get '/help', to: 'pages#help'
  get '/contact', to: 'pages#contact'
  post '/contact', to: 'pages#create_contact'

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'

  resources :prisons do
    resources :prisons, only: :index
    resources :dashboard, only: :index
    resources :caseload, only: %i[ index new ]
    get('/prisoners/:id' => 'prisoners#show', as: 'prisoner_show')
    get('/prisoners/:id/image.jpg' => 'prisoners#image', as: 'prisoner_image')
    resources :allocations, only: %i[ show new create edit update ], param: :nomis_offender_id, path_names: {
        new: ':nomis_offender_id/new',
    }
    get('/allocations/:nomis_offender_id/history' => 'allocations#history', as: 'allocation_history')
    get('/allocations/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocations#confirm', as: 'confirm_allocation')
    get('/reallocations/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocations#confirm_reallocation', as: 'confirm_reallocation')
    resource :case_information, only: %i[new create edit update], controller: 'case_information', path_names: {
        new: 'new/:nomis_offender_id',
        edit: 'edit/:nomis_offender_id'
    }
    resources :coworking, only: %i[new], param: :nomis_offender_id, path_names: {
        new: ':nomis_offender_id/new'
    }
    post('/coworking', to: 'coworking#create', as: 'coworking')
    get('/coworking/confirm/:nomis_offender_id/:primary_pom_id/:secondary_pom_id' => 'coworking#confirm', as: 'confirm_coworking_allocation')

    resource :overrides,  only: %i[ new create ], path_names: { new: 'new/:nomis_offender_id/:nomis_staff_id'}
    resources :poms, only: %i[ index show edit update ], param: :nomis_staff_id

    get('/search' => 'search#search')

    get('/summary' => 'summary#index')
    get('/summary/allocated' => 'summary#allocated')
    get('/summary/unallocated' => 'summary#unallocated')
    get('/summary/pending' => 'summary#pending')
  end

  resources :health, only: %i[ index ], controller: 'health'
  resources :status, only: %i[ index ], controller: 'status'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  mount Flipflop::Engine => "/flip-flop-admin"
end
