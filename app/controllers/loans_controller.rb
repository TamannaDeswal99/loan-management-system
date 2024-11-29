class LoansController < ApplicationController
  before_action :set_loan, except: [:index, :new, :create]
  before_action :ensure_can_repay, only: [:repay]

  def index
    @loans = current_user.loans.order(created_at: :desc)
  end

  def show
    @total_amount_due = @loan.total_amount_due
    @can_repay = @loan.can_repay?
    @interest_accruals = @loan.interest_accruals.order(created_at: :desc)
  end

  def new
    @loan = current_user.loans.new
  end

  def create
    @loan = current_user.loans.new(loan_params)
    if @loan.save
      redirect_to @loan, notice: 'Loan request was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def accept
    if @loan.may_accept?
      ActiveRecord::Base.transaction do
        @loan.accept!
        @loan.transfer_funds
      end
      redirect_to @loan, notice: 'Loan terms accepted. Funds have been transferred.'
    else
      redirect_to @loan, alert: 'Cannot accept loan at this time.'
    end
  end

  def reject
    if @loan.may_reject?
      @loan.reject!
      redirect_to @loan, notice: 'Loan has been rejected.'
    else
      redirect_to @loan, alert: 'Cannot reject loan at this time.'
    end
  end

  def request_readjustment
    if @loan.may_request_readjustment?
      @loan.request_readjustment!
      redirect_to @loan, notice: 'Readjustment has been requested.'
    else
      redirect_to @loan, alert: 'Cannot request readjustment at this time.'
    end
  end
  
  def edit_readjustment
  end

  def update_readjustment
    if @loan.readjust_terms(
        new_amount: loan_params[:amount],
        new_interest_rate: loan_params[:interest_rate],
        adjusted_by: 'user'
      )
      redirect_to @loan, notice: 'Loan readjustment has been submitted.'
    else
      flash.now[:alert] = "Failed to submit readjustment: #{@loan.errors.full_messages.to_sentence}"
      render :edit_readjustment
    end
  end

  def repay
    LoanRepaymentService.repay(@loan)
    redirect_to @loan, notice: 'Loan has been successfully repaid.'
  rescue StandardError => e
    redirect_to @loan, alert: "Repayment failed: #{e.message}"
  end

  private

  def set_loan
    @loan = current_user.loans.find(params[:id])
  end

  def loan_params
    params.require(:loan).permit(:amount, :interest_rate)
  end

  def ensure_can_repay
    unless @loan.can_repay?
      redirect_to @loan, alert: 'Insufficient balance to repay the loan.'
    end
  end
end