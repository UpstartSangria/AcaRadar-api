# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:papers) do
      add_column :origin_id, String, unique: true, null: false
    end
  end
end
