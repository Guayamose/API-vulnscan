class CreateRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :jti
      t.datetime :revoked_at
      t.datetime :expires_at

      t.timestamps
    end
    add_index :refresh_tokens, :jti
  end
end
