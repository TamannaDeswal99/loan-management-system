class Wallet < ApplicationRecord
  belongs_to :user

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def credit!(amount)
    update!(balance: balance + amount)
  end

  def debit!(amount)
    update!(balance: balance - amount)
  end
end
