class CreateInterestAccruals < ActiveRecord::Migration[7.0]
  def change
    create_table :interest_accruals do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :amount, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.timestamps
    end
  end
end