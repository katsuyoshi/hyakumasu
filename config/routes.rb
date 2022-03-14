Rails.application.routes.draw do

  resources :users, only: [] do
    collection do
    end
    member do
      get :show
      get :image
      get :preview_image
      get :images
      post :start
      get :play
      put :input
      get :finished
    end
  end

  get '/line/preview_image'   => 'linebot#preview_image'
  get '/line/image'           => 'linebot#image'
  get '/image'                => 'linebot#image'
  post '/callback'            => 'linebot#callback'

  get 'welcome/index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'welcome#index'
end
