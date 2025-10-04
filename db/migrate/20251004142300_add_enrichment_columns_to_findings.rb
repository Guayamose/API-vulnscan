class AddEnrichmentColumnsToFindings < ActiveRecord::Migration[7.1]
  def change
    change_table :findings, bulk: true do |t|
      t.string  :title
      t.text    :summary
      t.text    :recommendation
      t.string  :engine
      t.jsonb   :owasp
      t.jsonb   :cwe
      t.jsonb   :references
      t.jsonb   :metadata, default: {}

      t.index :engine
      t.index :owasp, using: :gin
      t.index :cwe, using: :gin
      t.index :references, using: :gin
      t.index :metadata, using: :gin
    end
  end
end
