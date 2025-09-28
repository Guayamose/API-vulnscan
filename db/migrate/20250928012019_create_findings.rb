class CreateFindings < ActiveRecord::Migration[7.1]
  def change
    create_table :findings do |t|
      t.references :scan, null: false, foreign_key: true
      t.string :rule_id
      t.string :severity
      t.string :file_path
      t.integer :line
      t.text :message
      t.string :fingerprint_hint

      t.timestamps
    end
  end
end
