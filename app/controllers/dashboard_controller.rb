class DashboardController < ApplicationController
    before_action :authenticate_user!
  
    def index
      if current_user.admin?
        admin_dashboard
      else
        user_dashboard
      end
    end
  
    private
  
    def admin_dashboard
      admin = User.find_by(role: 'admin')
      @admin_wallet_balance = admin&.wallet&.balance || 0
      @total_loans = Loan.count
      @active_loans = Loan.where(state: :open).count
      @pending_requests = Loan.where(state: [:requested, :readjustment_requested]).count
      @total_amount_lent = Loan.where(state: :open).sum(:amount)
      
      @recent_loans = Loan.includes(:user)
                         .order(created_at: :desc)
                         .limit(5)
      
      @loans_by_state = Loan.group(:state).count
  
      render 'admin_dashboard'
    end
  
    def user_dashboard
      @loans = current_user.loans
      @active_loans = @loans.where(state: :open)
      @pending_loans = @loans.where(state: [:requested, :approved, :waiting_for_adjustment_acceptance, :readjustment_requested])
      @completed_loans = @loans.where(state: [:close])
      @rejected_loans = @loans.where(state: :rejected)
      
      @total_borrowed = @active_loans.sum(:amount)
      @total_due = @active_loans.sum(&:total_amount_due)
      
      @wallet_balance = current_user.wallet&.balance || 0
  
      render 'user_dashboard'
    end
  end