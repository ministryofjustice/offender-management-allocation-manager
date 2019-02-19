Rails.application.routes.draw do
  root to: 'dashboard#index'

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'
  get('/summary' => 'summary#index')
  get('/prisoners/:id' => 'prisoners#show', as: 'prisoners_show')
  get('/allocations/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocations#confirm', as: 'confirm_allocations')
  get('/poms/:nomis_staff_id/my_caseload' => 'poms#my_caseload', as: 'my_caseload')
  get('/poms/:nomis_staff_id/new_cases' => 'poms#new_cases', as: 'new_cases')
  
  resources :health, only: %i[ index ], controller: 'health'
  resources :status, only: %i[ index ], controller: 'status'
  resources :poms, only: %i[ index show edit ], param: :nomis_staff_id
  resource :overrides,  only: %i[ new create ], path_names: { new: 'new/:nomis_offender_id/:nomis_staff_id'}
  resource :allocations, only: %i[ new create ], path_names: {
    new: 'new/:nomis_offender_id',
    confirm: 'confirm/:nomis_offender_id/:nomis_staff_id'
  }
  resource :case_information, only: %i[new create edit update], controller: 'case_information', path_names: {
    new: 'new/:nomis_offender_id',
    edit: 'edit/:nomis_offender_id'
  }
end
