Rails.application.routes.draw do
  get 'status/index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'status#index'
end
