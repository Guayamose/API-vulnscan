# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_28_012019) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "findings", force: :cascade do |t|
    t.bigint "scan_id", null: false
    t.string "rule_id"
    t.string "severity"
    t.string "file_path"
    t.integer "line"
    t.text "message"
    t.string "fingerprint_hint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "summary"
    t.text "recommendation"
    t.string "engine"
    t.jsonb "owasp"
    t.jsonb "cwe"
    t.jsonb "references"
    t.jsonb "metadata", default: {}
    t.index ["cwe"], name: "index_findings_on_cwe", using: :gin
    t.index ["engine"], name: "index_findings_on_engine"
    t.index ["fingerprint_hint"], name: "index_findings_on_fingerprint_hint"
    t.index ["metadata"], name: "index_findings_on_metadata", using: :gin
    t.index ["owasp"], name: "index_findings_on_owasp", using: :gin
    t.index ["references"], name: "index_findings_on_references", using: :gin
    t.index ["scan_id"], name: "index_findings_on_scan_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "jti"
    t.datetime "revoked_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_refresh_tokens_on_jti"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "scans", force: :cascade do |t|
    t.string "idempotency_key"
    t.string "body_hash"
    t.string "org"
    t.string "user_ref"
    t.string "project_slug"
    t.string "scan_type"
    t.string "commit_sha"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "findings_ingested"
    t.integer "deduped"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_scans_on_idempotency_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "role"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "findings", "scans"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "users", "organizations"
end
