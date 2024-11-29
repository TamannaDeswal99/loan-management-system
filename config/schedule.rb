class InterestCalculationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 3
  
    def perform
      # Find all open loans and calculate interest for each
      Loan.where(state: :open).find_each do |loan|
        calculate_interest(loan)
      rescue StandardError => e
        Rails.logger.error "Interest calculation failed for loan ##{loan.id}: #{e.message}"
      end
    end
  
    private
  
    def calculate_interest(loan)
      ActiveRecord::Base.transaction do
        start_time = loan.last_interest_calculation_at || loan.opened_at
        end_time = Time.current
        
        # Calculate interest for the 5-minute period
        period_interest = calculate_period_interest(loan, start_time, end_time)
        
        # Create interest accrual record
        InterestAccrual.create!(
          loan: loan,
          amount: period_interest,
          start_time: start_time,
          end_time: end_time
        )
  
        # Update loan's total interest
        loan.update!(
          total_interest: loan.total_interest + period_interest,
          last_interest_calculation_at: end_time
        )
  
        Rails.logger.info "Interest calculated for loan ##{loan.id}: #{period_interest} (Total: #{loan.total_interest})"
      end
    end
  
    def calculate_period_interest(loan, start_time, end_time)
      # Calculate hours elapsed
      hours = ((end_time - start_time) / 1.hour).to_f
      
      # Convert annual interest rate to hourly rate
      # Formula: annual_rate / (365 days * 24 hours * 100 for percentage)
      hourly_rate = loan.interest_rate / (365 * 24 * 100)
      
      # Calculate interest on principal amount
      interest = loan.amount * hourly_rate * hours
      
      # Round to 2 decimal places
      interest.round(2)
    end
  end