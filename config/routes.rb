Rails.application.routes.draw do
  root to: 'dashboard#index'

  match "/401", :to => "errors#unauthorized", :via => :all
  match "/404", :to => "errors#not_found", :via => :all
  match "/500", :to => "errors#internal_server_error", :via => :all
  match "/503", :to => "errors#internal_server_error", :via => :all

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'
  get('/summary' => 'summary#index')
  get('/prisoners/:id' => 'prisoners#show', as: 'prisoners_show')
  get('/allocations/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocations#confirm', as: 'confirm_allocations')
  get('/poms/:nomis_staff_id/my_caseload' => 'poms#my_caseload', as: 'my_caseload')
  get('/poms/:nomis_staff_id/new_cases' => 'poms#new_cases', as: 'new_cases')

  resources :health, only: %i[ index ], controller: 'health'
  resources :status, only: %i[ index ], controller: 'status'
  resource :overrides,  only: %i[ new create ], path_names: { new: 'new/:nomis_offender_id/:nomis_staff_id'}
  resources :poms, only: %i[ index show edit update ], param: :nomis_staff_id
  resource :allocations, only: %i[ new create edit ], path_names: {
    new: 'new/:nomis_offender_id',
    edit: 'edit/:nomis_offender_id',
    confirm: 'confirm/:nomis_offender_id/:nomis_staff_id'
  }
  resource :case_information, only: %i[new create edit update], controller: 'case_information', path_names: {
      new: 'new/:nomis_offender_id',
      edit: 'edit/:nomis_offender_id'
  }
end
