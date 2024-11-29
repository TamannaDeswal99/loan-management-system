class CreateLoanAdjustments < ActiveRecord::Migration[7.2]
  def change
    create_table :loan_adjustments do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :previous_amount, precision: 10, scale: 2
      t.decimal :new_amount, precision: 10, scale: 2
      t.decimal :previous_interest_rate, precision: 5, scale: 2
      t.decimal :new_interest_rate, precision: 5, scale: 2

      t.timestamps
    end
  end
end
