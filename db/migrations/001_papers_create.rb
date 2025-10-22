# frozen_string_literal: true

# :id, :title, :published, :updated, :summary, :authors, :categories, :links, :journal_ref
Sequel.migration do
  change do
    create_table(:papers) do
      primary_key :id
      String :title
      DateTime :published
      DateTime :updated
      String :summary
      String :authors
      String :categories
      String :links
      String :journal_ref
    end
  end
end
