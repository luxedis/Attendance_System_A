Rails.application.routes.draw do
  get 'hubs/index'

  get 'hubs/show'

  root 'static_pages#top'
  get '/signup', to: 'users#new'
  
  # ログイン機能
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  resources :users do
    member do
      get 'edit_basic_info' # 基本情報編集
      patch 'update_basic_info' # 基本情報更新
      patch 'update_all_users_basic_info' # ヘッダーから全ユーザーの勤務時間を一括更新
      get 'attendances/edit_one_month' # 勤怠編集ページのルート
      patch 'attendances/update_one_month' # 1ヶ月分まとめて更新ボタン/勤怠編集画面
      patch 'attendances/monthly_approval_request' # 1ヶ月分の勤怠承認/上長への申請ボタン
      get 'confirm_one_month' # 各お知らせモーダル内の勤怠確認ボタン
    end
    collection do
      post :import # csvのインポート
      get :at_work_index # 出勤中社員一覧
    end
    
    resources :attendances, only: :update do # 出勤登録ボタン
      member do # memberにするとurlにidが付けられる
        get 'edit_overtime_request' # 残業申請モーダル attendance直下のmemberだからurlにattendance_id がつく
        patch 'update_overtime_request' # 残業申請モーダル。ここで更新
      end
      collection do
        get 'edit_approval_overtime' # collection付けるとurlにidが付かなくてOKになる
        patch 'update_approval_overtime'
        get 'approval_monthly_edit' # 勤怠変更申請お知らせモーダル表示
        patch 'update_approval_monthly_edit' # 勤怠変更申請お知らせモーダル更新
        get 'approval_monthly_report' # 一ヶ月分勤怠申請モーダル表示
        patch 'update_approval_monthly_report' # 一ヶ月分勤怠申請モーダル更新
        get 'attendance_log' # 勤怠ログ
      end
    end
  end
  
  # 拠点情報
  resources :hubs
end