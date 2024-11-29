class AddAdjustedByToLoanAdjustments < ActiveRecord::Migration[7.2]
  def change
    add_column :loan_adjustments, :adjusted_by, :string
  end
end
