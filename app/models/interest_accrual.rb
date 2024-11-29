class InterestAccrual < ApplicationRecord
    belongs_to :loan
  
    validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :start_time, :end_time, presence: true

    private

    def end_time_after_start_time
      return unless start_time && end_time
      errors.add(:end_time, "must be after start time") if end_time <= start_time
    end
  end