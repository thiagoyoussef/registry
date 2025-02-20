class Account < ApplicationRecord
  extend ToCsv
  include Versions

  belongs_to :registrar, required: true
  has_many :account_activities

  validates :account_type, presence: true

  CASH = 'cash'

  def activities
    account_activities
  end
end
