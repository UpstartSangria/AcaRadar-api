# frozen_string_literal: true

#  :name, :first_name, :last_name
Sequel.migration do
  change do
    create_table(:authors) do
      primary_key :author_id
      foreign_key :paper_id, :papers

      String :name
      String :first_name
      String :last_name
    end
  end
end
