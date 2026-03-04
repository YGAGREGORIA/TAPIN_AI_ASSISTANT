class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  belongs_to :studio, optional: true

  has_many :check_ins, dependent: :destroy
  has_many :user_rewards, dependent: :destroy
  has_many :rewards, through: :user_rewards

  def admin?
    role == "admin"
  end

  def customer?
    role == "customer"
  end
end
