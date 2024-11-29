class AddInterestFieldsToLoans < ActiveRecord::Migration[7.0]
  def change
    add_column :loans, :total_interest, :decimal, precision: 10, scale: 2, default: 0
    add_column :loans, :last_interest_calculation_at, :datetime
  end
end