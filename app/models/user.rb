class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :wallet
  has_many :loans

  after_create :create_wallet 

  def admin?
    role == 'admin'
  end

  private

  def create_wallet
    initial_balance = admin? ? 1_000_000 : 10_000 # 10 lakhs for admin, 10k for users
    create_wallet!(balance: initial_balance)
  end
end
