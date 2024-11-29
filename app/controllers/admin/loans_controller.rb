class Admin::LoansController < Admin::BaseController
    before_action :set_loan, only: [:show, :edit, :update, :approve, :reject, :accept_readjustment, :reject_readjustment, :edit_readjustment, :update_readjustment]
  
    def index
      @loans = Loan.includes(:user).order(created_at: :desc)
    end
  
    def show
      @loan_adjustments = @loan.loan_adjustments.order(created_at: :desc)
    end

    def edit
    end
  
    def update
      if @loan.adjust_terms(
          new_amount: loan_params[:amount],
          new_interest_rate: loan_params[:interest_rate]
        )
        redirect_to [:admin, @loan], notice: 'Loan has been adjusted and is waiting for user acceptance.'
      else
        flash.now[:alert] = 'Failed to adjust loan'
        render :edit
      end
    end

    def accept_readjustment
      if @loan.readjustment_requested?
        ActiveRecord::Base.transaction do
          # The loan is already updated with the user's requested values
          @loan.approve! # This will change state to 'approved'
          redirect_to [:admin, @loan], notice: 'Readjustment request has been accepted. Waiting for user confirmation.'
        end
      else
        redirect_to [:admin, @loan], alert: 'Cannot accept readjustment at this time.'
      end
    end
  
    def reject_readjustment
      if @loan.readjustment_requested?
        @loan.reject!
        redirect_to [:admin, @loan], notice: 'Readjustment request has been rejected.'
      else
        redirect_to [:admin, @loan], alert: 'Cannot reject readjustment at this time.'
      end
    end

    def edit_readjustment
      @loan = Loan.find(params[:id])
    end
  
    def update_readjustment
      if @loan.readjust_terms(
          new_amount: loan_params[:amount],
          new_interest_rate: loan_params[:interest_rate],
          adjusted_by: 'admin'
        )
        redirect_to [:admin, @loan], notice: 'Loan has been readjusted.'
      else
        flash.now[:alert] = "Failed to readjust loan: #{@loan.errors.full_messages.to_sentence}"
        render :edit_readjustment
      end
    end

    def reject_readjustment
      if @loan.readjustment_requested?
        @loan.reject!
        redirect_to [:admin, @loan], notice: 'Readjustment request has been rejected.'
      else
        redirect_to [:admin, @loan], alert: 'Cannot reject readjustment at this time.'
      end
    end
  
    def approve
      if @loan.approve!
        redirect_to [:admin, @loan], notice: 'Loan approved successfully.'
      else
        redirect_to [:admin, @loan], alert: 'Unable to approve loan.'
      end
    end
  
    def reject
      if @loan.reject!
        redirect_to [:admin, @loan], notice: 'Loan rejected successfully.'
      else
        redirect_to [:admin, @loan], alert: 'Unable to reject loan.'
      end
    end
  
    def adjust
      if @loan.modify_terms(
          new_amount: loan_params[:amount],
          new_interest_rate: loan_params[:interest_rate]
        )
        redirect_to [:admin, @loan], notice: 'Loan adjusted successfully.'
      else
        redirect_to [:admin, @loan], alert: 'Unable to adjust loan.'
      end
    end
  
    private
  
    def set_loan
      @loan = Loan.find(params[:id])
    end
  
    def loan_params
      params.require(:loan).permit(:amount, :interest_rate)
    end
  end