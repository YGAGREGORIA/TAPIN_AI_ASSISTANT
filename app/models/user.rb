class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :chats, dependent: :destroy
  has_many :check_ins
  has_many :studios, through: :check_ins
end
