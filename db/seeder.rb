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
  end

  def self.create_tables
    db.execute('CREATE TABLE med (drugid INTEGER PRIMARY KEY AUTOINCREMENT, illnessid1 I, name TEXT NOT NULL, description TEXT)')
    db.execute('CREATE TABLE ill (illnessid INTEGER PRIMARY KEY AUTOINCREMENT, drugid1 I, name TEXT NOT NULL, description TEXT)')
    db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, password TEXT NOT NULL, is_admin BOOLEAN)')
  end

  def self.populate_tables
    password_hashed_admin = BCrypt::Password.create("admin")
    password_hashed_user = BCrypt::Password.create("user")
    db.execute('INSERT INTO med (name, description, illnessid1) VALUES ("drug 1", "first drug", "illness1")')
    db.execute('INSERT INTO ill (name, description, drugid1) VALUES ("illness 1", "first illness", "drug1")')
    db.execute('INSERT INTO users (username, password, is_admin) VALUES (?, ?, ?)',["admin", password_hashed_admin, true])
    db.execute('INSERT INTO users (username, password, is_admin) VALUES (?, ?, ?)',["user", password_hashed_user, false])
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