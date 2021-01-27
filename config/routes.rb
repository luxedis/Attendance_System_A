Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'
  
  # ログイン機能
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      patch 'update_all_users_basic_info' # 一括処理
      get 'attendances/edit_one_month' # 勤怠編集ページのルート
      patch 'attendances/update_one_month' # 1ヶ月分まとめて更新ボタン
    end
    resources :attendances, only: :update # 出勤登録ボタン
  end
end