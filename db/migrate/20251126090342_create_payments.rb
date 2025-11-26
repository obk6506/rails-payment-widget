class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.string :order_id
      t.string :payment_key
      t.integer :amount
      t.string :status
      t.string :order_name
      t.string :customer_email

      t.timestamps
    end
  end
end
