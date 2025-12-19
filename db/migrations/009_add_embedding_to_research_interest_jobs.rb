# frozen_string_literal: true

Sequel.migration do
    change do
      alter_table(:research_interest_jobs) do
        # Store the full embedding as base64 of float32 little-endian packed bytes
        add_column :embedding_b64, String, text: true
  
        # Helpful for debugging / validation
        add_column :embedding_dim, Integer
      end
    end
  end
  