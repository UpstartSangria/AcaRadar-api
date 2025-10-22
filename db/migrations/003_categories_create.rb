# frozen_string_literal: true

# :all, :primary
Sequel.migration do
  change do
    create_table(:categories) do
      primary_key :category_id
      String :all_categories
      String :primary_category
    end
  end
end
