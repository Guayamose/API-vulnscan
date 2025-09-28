class CreateScans < ActiveRecord::Migration[7.1]
  def change
    create_table :scans do |t|
      t.string :idempotency_key
      t.string :body_hash
      t.string :org
      t.string :user_ref
      t.string :project_slug
      t.string :scan_type
      t.string :commit_sha
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :findings_ingested
      t.integer :deduped
      t.string :status

      t.timestamps
    end
    add_index :scans, :idempotency_key, unique: true
    add_index :scans, :project_slug
  end
end
