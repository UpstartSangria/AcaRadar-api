# frozen_string_literal: true

# Helper to clean database during test runs
module DatabaseHelper
  def self.wipe_database
    # Ignore foreign key constraints when wiping tables
    AcaRadar::App.db.run('PRAGMA foreign_keys = OFF')
    AcaRadar::Database::PaperOrm.map(&:destroy)
    AcaRadar::Database::AuthorOrm.map(&:destroy)
    AcaRadar::Database::CategoryOrm.map(&:destroy)
    AcaRadar::App.db.run('PRAGMA foreign_keys = ON')
  end
end
