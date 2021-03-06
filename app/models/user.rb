class User < ApplicationRecord
  has_many :attendances, dependent: :destroy
  # 「remember_token」という仮想の属性を作成します。
  attr_accessor :remember_token
  before_save { self.email = email.downcase }
  
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 100 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  validates :affiliation, length: { in: 2..30 }, allow_blank: true # ユーザーの所属
  validates :basic_work_time, presence: true # ユーザーの基本勤務時間
  validates :designated_work_start_time, presence: true # ユーザーの指定勤務開始時間
  validates :designated_work_end_time, presence: true # ユーザーの指定勤務終了時間
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  
  # 渡された文字列のハッシュ値を返します。
  def User.digest(string)
    cost =
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end
  
  # ランダムなトークンを返します。
  def User.new_token
    SecureRandom.urlsafe_base64
  end
  
  # 永続セッションのため、ハッシュ化したトークンをデータベースに記憶します。
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
  # トークンがダイジェストと一致すればtrueを返します。
  def authenticated?(remember_token)
    # ダイジェストが存在しない場合はfalseを返して終了します。
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end
  
  # ユーザーのログイン情報を破棄します。
  def forget
    update_attribute(:remember_digest, nil)
  end
  
  def self.search(search) #このself.はUser.の意味(class Userだから) このserachにはnameパラメータが入る
    if search # searchが空白じゃなければ空白になるからif文実行している、空だったらfalseになるからelseへ飛ぶ
      User.where('name LIKE ?', "%#{search}%")
    else
      User.all
    end
  end
  
  # scv import
  def self.import(file) # ここのselfはページ上部のclass Userのuserの意味なので self=Userの意
    CSV.foreach(file.path, headers: true, encoding: 'Shift_JIS:UTF-8') do |row|
      # IDが見付かればレコードを呼び出し、見つからなければ新しくユーザーを作成
      user = User.find_by(email: row["email"]) || User.new
      # csvからデータを取得、設定する
      user.attributes = row.to_hash.slice(*update_attributes)
      # 保存
      user.save
    end
  end
  
  # 更新を許可するカラムを定義する
  def self.update_attributes
    ["name", "email", "affiliation", "employee_number", "uid", "basic_work_time", "designated_work_start_time", "designated_work_end_time", "superior", "admin", "password"]
  end
end