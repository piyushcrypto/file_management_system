Rails.application.routes.draw do
  devise_for :users
  
  resources :file_uploads, only: [:index, :new, :create, :destroy]

end
