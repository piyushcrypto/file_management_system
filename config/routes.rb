Rails.application.routes.draw do
  devise_for :users

  root 'file_uploads#index'
  
  resources :file_uploads, only: [:index, :new, :create, :destroy]

end