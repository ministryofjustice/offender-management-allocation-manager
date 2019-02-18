Rails.application.routes.draw do
  root to: 'dashboard#index'

  get '/status', to: 'status#index'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'

  get('health' => 'health#index')

  get('/summary' => 'summary#index')

  get('/poms' => 'poms#index')
  get('/poms/:id' => 'poms#show', as: 'poms_show')
  get('/poms/:id/edit' => 'poms#edit', as: 'poms_edit')
  get('/poms/:staff_id/my_caseload' => 'poms#my_caseload', as: 'my_caseload')
  get('/poms/:staff_id/new_cases' => 'poms#new_cases', as: 'new_cases')

  get('/prisoners/:id' => 'prisoners#show', as: 'prisoners_show')

  get('/allocations/:nomis_offender_id' => 'allocations#show',
      as: 'allocations_show')
  get('/allocations/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocations#new',
      as: 'new_allocations')

  get('/overrides/new/:nomis_offender_id/:nomis_staff_id' => 'overrides#new',
      as: 'new_overrides')

  resource :allocations, only: %i[ create ]
  resource :overrides,  only: %i[create]
  resource :case_information, only: %i[new create edit update], controller: 'case_information', path_names: {
      new: 'new/:nomis_offender_id',
      edit: 'edit/:nomis_offender_id'
  }
end
