class CreateFortuneLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :fortune_logs do |t|
      t.string :name
      t.text :content
      t.vector :embedding, limit: 768

      t.timestamps
    end
  end
end
