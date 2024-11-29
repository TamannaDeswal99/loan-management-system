class InterestCalculationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform(loan_id)
    loan = Loan.find(loan_id)
    return unless loan.state == 'open'  # Only calculate for open loans

    begin
      calculate_interest(loan)
      
      # Schedule next calculation in 5 minutes if loan is still open
      self.class.perform_in(5.minutes, loan_id) if loan.state == 'open'
    rescue StandardError => e
      Rails.logger.error "Interest calculation failed for loan ##{loan_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def calculate_interest(loan)
    ActiveRecord::Base.transaction do
      current_time = Time.current
      start_time = loan.last_interest_calculation_at || loan.opened_at
      
      return if start_time.nil? || current_time <= start_time
      period_interest = calculate_period_interest(loan, start_time, current_time)
      
      Rails.logger.info "Calculating interest for loan ##{loan.id}"
      Rails.logger.info "Start time: #{start_time}"
      Rails.logger.info "End time: #{current_time}"
      Rails.logger.info "Period interest: #{period_interest}"
      if period_interest > 0
        InterestAccrual.create!(
          loan: loan,
          amount: period_interest,
          start_time: start_time,
          end_time: current_time
        )

        loan.update!(
          total_interest: (loan.total_interest || 0) + period_interest,
          last_interest_calculation_at: current_time
        )

        Rails.logger.info "Created interest accrual for loan ##{loan.id}"
        Rails.logger.info "New total interest: #{loan.total_interest}"
      end
    end
  end

  def calculate_period_interest(loan, start_time, end_time)
    minutes = ((end_time - start_time) / 1.minute).to_f
    return 0 if minutes <= 0
  
    # Convert annual rate to per-minute rate
    # Formula: annual_rate / (365 days * 24 hours * 60 minutes * 100[for percentage])
    minute_rate = loan.interest_rate / (365 * 24 * 60 * 100)
    
    # Calculate interest: principal * rate * time
    interest = (loan.amount * minute_rate * minutes)
    interest
  end
end