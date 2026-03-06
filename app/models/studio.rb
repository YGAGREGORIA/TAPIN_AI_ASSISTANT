class Studio < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :check_ins, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :deals, dependent: :destroy
  has_many :rewards, dependent: :destroy
end
