# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:papers) do
      primary_key :paper_id
      String :title
      DateTime :published
      DateTime :updated
      String :summary
      String :links
      String :journal_ref
    end
  end
end
