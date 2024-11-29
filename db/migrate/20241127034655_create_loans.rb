class CreateLoans < ActiveRecord::Migration[7.2]
  def change
    create_table :loans do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale:2, null: false
      t.decimal :interest_rate, precision: 5, scale: 2, null: false
      t.string :state, null: false, default: 'requested'
      t.datetime :opened_at

      t.timestamps
    end
  end
end
