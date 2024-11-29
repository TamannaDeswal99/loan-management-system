class Loan < ApplicationRecord
  include AASM

  belongs_to :user
  has_many :loan_adjustments
  has_many :interest_accruals

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, presence: true, numericality: { greater_than: 0 }

  aasm column: 'state' do
    state :requested, initial: true
    state :approved
    state :rejected
    state :open
    state :close
    state :waiting_for_adjustment_acceptance
    state :readjustment_requested

    event :approve do
      transitions from: [:requested, :readjustment_requested], to: :approved,
      after: :process_loan_approval
    end

    event :reject do
      transitions from: [:requested, :approved, :waiting_for_adjustment_acceptance, :readjustment_requested], 
                  to: :rejected
    end

    event :adjust do
      transitions from: [:requested, :readjustment_requested], 
                  to: :waiting_for_adjustment_acceptance
    end

    event :request_readjustment do
      transitions from: :waiting_for_adjustment_acceptance, 
                  to: :readjustment_requested
    end

    event :accept do
      transitions from: [:approved, :waiting_for_adjustment_acceptance], 
                  to: :open,
                  after: [:set_opened_at, :start_interest_calculation]
    end

    event :close do
      transitions from: [:open, :approved], to: :close,
                after: :calculate_final_interest
    end
  end

  def total_amount_due
    amount + total_interest
  end

  def can_repay?
    user.wallet.balance >= total_amount_due
  end

  def adjust_terms(new_amount:, new_interest_rate:)
    ActiveRecord::Base.transaction do
      # Create adjustment record
      loan_adjustments.create!(
        previous_amount: amount,
        new_amount: new_amount,
        previous_interest_rate: interest_rate,
        new_interest_rate: new_interest_rate,
        adjusted_by: 'admin'
      )

      # Update loan terms
      update!(
        amount: new_amount,
        interest_rate: new_interest_rate
      )

      # Change state
      adjust!
    end
    true
  rescue StandardError => e
    Rails.logger.error "Failed to adjust loan terms: #{e.message}"
    false
  end

  def readjust_terms(new_amount:, new_interest_rate:, adjusted_by:)
    ActiveRecord::Base.transaction do
      # Create adjustment record
      loan_adjustments.create!(
        previous_amount: amount,
        new_amount: new_amount,
        previous_interest_rate: interest_rate,
        new_interest_rate: new_interest_rate,
        adjusted_by: adjusted_by
      )

      # Update loan terms
      update!(
        amount: new_amount,
        interest_rate: new_interest_rate
      )

      # Change state
      adjusted_by == 'admin'? adjust! : request_readjustment!
    end
    true
  rescue StandardError => e
    Rails.logger.error "Failed to readjust loan terms: #{e.message}"
    errors.add(:base, e.message)
    false
  end

  def modify_terms(new_amount:, new_interest_rate:, adjusted_by: nil)
    ActiveRecord::Base.transaction do
      loan_adjustments.create!(
        previous_amount: amount,
        new_amount: new_amount,
        previous_interest_rate: interest_rate,
        new_interest_rate: new_interest_rate,
        adjusted_by: adjusted_by
      )

      update!(
        amount: new_amount,
        interest_rate: new_interest_rate
      )

      adjust!
    end
    true
  rescue StandardError => e
    Rails.logger.error "Failed to modify loan terms: #{e.message}"
    errors.add(:base, e.message)
    false
  end

  def transfer_funds
    ActiveRecord::Base.transaction do
      admin = User.find_by(role: 'admin')
      admin_wallet = admin.wallet
      user_wallet = user.wallet

      admin_wallet.debit!(amount)    
      user_wallet.credit!(amount)  
    end
  end

  def interest_calculation_status
    return 'Not started' if last_interest_calculation_at.nil?
    return 'Completed' unless state == 'open'
    
    minutes_since_last = ((Time.current - last_interest_calculation_at) / 60).round
    "Last calculated #{minutes_since_last} minutes ago"
  end

  def total_accrued_interest
    interest_accruals.sum(:amount)
  end

  private

  def set_opened_at
    update(
      opened_at: Time.current,
      last_interest_calculation_at: Time.current,
      total_interest: 0
      )
  end

  def process_loan_approval
    ActiveRecord::Base.transaction do
      credit_user_wallet
    end
  end

  def credit_user_wallet
    user.wallet.credit!(amount)
    update!(
      state: 'open',
      opened_at: Time.current,
      last_interest_calculation_at: Time.current,
      total_interest: 0
    )
  end

  def start_interest_calculation
    Rails.logger.info "Starting interest calculation for loan ##{id}"
    InterestCalculationWorker.perform_async(id)
  end

  def calculate_final_interest
    current_time = Time.current
    start_time = last_interest_calculation_at || opened_at
    
    return if start_time.nil? || current_time <= start_time
    
    period_interest = calculate_period_interest(start_time, current_time)
    
    if period_interest > 0
      InterestAccrual.create!(
        loan: self,
        amount: period_interest,
        start_time: start_time,
        end_time: current_time
      )
      
      update!(
        total_interest: (total_interest || 0) + period_interest,
        last_interest_calculation_at: current_time
      )
    end
  end

  def calculate_period_interest(start_time, end_time)
    return 0 if start_time.nil? || end_time.nil?
    
    hours = ((end_time - start_time) / 1.hour).to_f
    return 0 if hours <= 0

    hourly_rate = interest_rate / (365 * 24 * 100)
    (amount * hourly_rate * hours).round(2)
  end
end
