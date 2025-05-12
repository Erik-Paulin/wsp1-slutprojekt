require 'sqlite3'
require 'bcrypt'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS med')
    db.execute('DROP TABLE IF EXISTS ill')
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS user_med')
    db.execute('DROP TABLE IF EXISTS med_ill')
  end

  def self.create_tables
    db.execute('CREATE TABLE med (medid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT)')
    db.execute('CREATE TABLE ill (illid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT)')
    db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, password TEXT NOT NULL, is_admin INTEGER)')
    db.execute('CREATE TABLE med_ill (med_id INTEGER, ill_id INTEGER, FOREIGN KEY (med_id) REFERENCES med(medid), FOREIGN KEY (ill_id) REFERENCES ill(illid), PRIMARY KEY (med_id, ill_id))')
  end

  def self.populate_tables
    password_hashed_admin = BCrypt::Password.create("admin")
    password_hashed_user = BCrypt::Password.create("user")

    db.execute('INSERT INTO med (name, description) VALUES ("Drug 1", "First drug")')
    db.execute('INSERT INTO med (name, description) VALUES ("Drug 2", "Second drug")')

    db.execute('INSERT INTO ill (name, description) VALUES ("Illness 1", "First illness")')
    db.execute('INSERT INTO ill (name, description) VALUES ("Illness 2", "Second illness")')

    db.execute('INSERT INTO users (username, password, is_admin) VALUES (?, ?, ?)',["admin", password_hashed_admin, 1])
    db.execute('INSERT INTO users (username, password, is_admin) VALUES (?, ?, ?)',["user", password_hashed_user, 0])

    db.execute('INSERT INTO med_ill (med_id, ill_id) VALUES (1, 1)')
    db.execute('INSERT INTO med_ill (med_id, ill_id) VALUES (2, 2)')
    db.execute('INSERT INTO med_ill (med_id, ill_id) VALUES (1, 2)')
  end

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/drugs.sqlite')
    @db.results_as_hash = true
    @db
  end
end

Seeder.seed!