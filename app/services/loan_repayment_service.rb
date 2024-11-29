class LoanRepaymentService
  def self.repay(loan)
    new(loan).repay
  end

  def initialize(loan)
    @loan = loan
    @user = loan.user
    @admin = User.find_by(role: 'admin')
  end

  def repay
    raise "Insufficient balance" unless @loan.can_repay?

    ActiveRecord::Base.transaction do
      calculate_final_interest
      amount_to_repay = @loan.total_amount_due
      
      @user.wallet.debit!(amount_to_repay)
      @admin.wallet.credit!(amount_to_repay)

      @loan.close!
    end
  end

  private

  def calculate_final_interest
    current_time = Time.current
    start_time = @loan.last_interest_calculation_at || @loan.opened_at
    
    return if start_time.nil? || current_time <= start_time
    
    period_interest = calculate_period_interest(start_time, current_time)
    
    if period_interest > 0
      InterestAccrual.create!(
        loan: @loan,
        amount: period_interest,
        start_time: start_time,
        end_time: current_time
      )
      
      @loan.update!(
        total_interest: (@loan.total_interest || 0) + period_interest,
        last_interest_calculation_at: current_time
      )
    end
  end

  def calculate_period_interest(start_time, end_time)
    hours = ((end_time - start_time) / 1.hour).to_f
    return 0 if hours <= 0

    hourly_rate = @loan.interest_rate / (365 * 24 * 100)
    (@loan.amount * hourly_rate * hours).round(2)
  end
end