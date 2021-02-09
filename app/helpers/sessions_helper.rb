module SessionsHelper
  
  # 引数に渡されたユーザーオブジェクトでログインします。
  def log_in(user)
    session[:user_id] = user.id
  end
  
  # 永続的セッションを記憶します(Userモデルを参照)
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end
  
  # 永続的セッションをはきします
  def forget(user)
    user.forget # Userモデル参照
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
  
  # セッションと@current_userを破棄
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
  
  # 一時的セッションにいるユーザーを返します。
  # それ以外の場合はcookiesに対応するユーザーを返します。
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id) #emailで探したid
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user # log_inにuserという引数を渡している
        @current_user = user #35行目のuserだからviewに渡す必要がないからこの書き方このコントローラで完結するカラム名だから@入らない
      end
    end
  end
  
  # 渡されたユーザーがログイン済みのユーザーであればtrueを返します。
  def current_user?(user) # @userがセットされる
    user == current_user #31行目からのcurrent_user/@current_userの中身を観にいっている。
  end
  
  # 現在ログイン中のユーザーがいればtrue,そうでなければfalseを返します。
  def logged_in?
    !current_user.nil?
  end
  
  # 記憶しているURLまたはデフォルトURLにリダイレクト
  def redirect_back_or(default_url)
    redirect_to(session[:forwarding_url] || default_url)
    session.delete(:forwarding_url)
  end
  
  # アクセスしようとしたURLを記憶する。
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end