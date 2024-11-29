class LoanAdjustment < ApplicationRecord
  belongs_to :loan

  validates :new_amount, :new_interest_rate, presence: true 
  validates :new_amount, :new_interest_rate, numericality: { greater_than: 0 }
  validates :adjusted_by, presence: true, inclusion: { in: ['user', 'admin'] }
end
