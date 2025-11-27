Rails.application.routes.draw do

  get "saju", to: "saju#index"
  post "saju/stream", to: "saju#stream" # post로 변경
  get "saju/logs", to: "saju#logs"

  
  resource :session
  resources :passwords, param: :token
  resources :posts
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "posts#index"

  get "payment", to: "payments#index"   # 결제 버튼 있는 페이지
  get "payment/success", to: "payments#success" # 결제 성공 후 돌아오는 곳
  get "payment/fail", to: "payments#fail"       # 결제 실패 후 돌아오는 곳


end
