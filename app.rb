require 'sinatra'
require 'bcrypt'
require 'dotenv'

Dotenv.load

class App < Sinatra::Base
  use Rack::Session::Cookie, key: "rack.session", path:"/", secret: ENV["SESSION_SECRET"]

    helpers do
      def admin_protected()
        redirect('/unauthorized') if !session[:is_admin]
      end
      def user_protected()
        redirect('/unauthorized') if session[:user_id].nil?
      end

    end

    def db
      return @db if @db

      db_path = "db/drugs.sqlite"
      @db = SQLite3::Database.new(db_path)
      @db.results_as_hash = true

      return @db
    end

    configure do
      enable :sessions
      set :session_secret, SecureRandom.hex(64)
    end

    get '/' do
      @meds = db.execute('SELECT * FROM med')
      @ills = db.execute('SELECT * FROM ill')
      redirect('/index')
    end
    get '/index' do
      @meds = db.execute('SELECT * FROM med')
      @ills = db.execute('SELECT * FROM ill')
      erb(:"index")
    end

    get '/logerror' do
      erb(:"logerror")
    end

    get '/logout' do
      p "/logout : Logging out"
      session.clear
      redirect '/index'
    end

    get '/login' do
      erb(:login)
    end

    post '/login' do
      request_username = params[:username]
      request_plain_password = params[:password]

      user = db.execute("SELECT * FROM users WHERE username = ?", request_username).first

      unless user
        p "Invalid username."
        status 401
        redirect '/logerror'
      end

      db_id = user["id"].to_i
      db_password_hashed = user["password"].to_s

      bcrypt_db_password = BCrypt::Password.new(db_password_hashed)

      if bcrypt_db_password == request_plain_password
        session[:user_id] = db_id
        session[:is_admin] = user['is_admin'] == 1
        redirect '/index'
      else
        status 401
        redirect '/logerror'
      end

    end
    get '/unauthorized' do
      erb(:"unauthorized")
    end
    get '/user/prescript' do
      user_protected()

      user_med_id = session[:user_id]
      @meds = db.execute('SELECT med FROM user_med WHERE user_id=?'[user_med_id])

      erb(:"/user/prescript")
    end

    #MEDS
    get '/meds/show_med/:id' do |id|
      @med = db.execute('SELECT * FROM med WHERE medid = ?', [id.to_i]).first
      if @med
        @ills = db.execute('SELECT ill.* FROM ill INNER JOIN med_ill ON ill.illid = med_ill.ill_id WHERE med_ill.med_id = ?', [id.to_i])
        erb(:"/meds/show_med")
      else
        halt 404, "Medicine not found"
      end
    end

    #New medicine
    get '/admin/meds/new_med' do
      admin_protected()
      @ills = db.execute('SELECT * FROM ill')
      erb(:"/admin/meds/new_med")
    end

    # New medicine with illness
    post '/meds/med' do
      admin_protected()
      # Get the parameters from the form
      name = params[:med_name]
      desc = params[:med_desc]
      ill_ids = params[:ill_ids] || []

      db.execute("INSERT INTO med (name, description) VALUES (?, ?)", [name, desc])
      med_id = db.last_insert_row_id

      ill_ids.each do |ill_id|
        db.execute("INSERT INTO med_ill (med_id, ill_id) VALUES (?, ?)", [med_id, ill_id])
      end

      redirect('/index')
    end

    #Edit medicine
    get '/admin/meds/:id/edit_med' do |id|
      admin_protected()

      @id = params[:id]
      @med = db.execute('SELECT * FROM med WHERE medid=?', [id.to_i]).first
      unless @med
        halt 404, "Medicine not found"
      end
      @ills = db.execute('SELECT * FROM ill')
      @meds = db.execute('SELECT * FROM med')

      @med_ills = db.execute('SELECT ill.* FROM ill INNER JOIN med_ill ON ill.illid = med_ill.ill_id WHERE med_ill.med_id = ?', [id.to_i])
      
      erb(:"/admin/meds/edit_med")
    end

    post '/admin/meds/:id/edit_med/update' do |id|
      p @med
      admin_protected()
      name = params[:med_name]
      desc = params[:med_desc]
      ill_ids = params[:ill_ids] || []

      db.execute("UPDATE med SET name=?, description=? WHERE medid=?", [name, desc, id])

      db.execute("DELETE FROM med_ill WHERE med_id = ?", [id])

      ill_ids.each do |ill_id|
        db.execute("INSERT INTO med_ill (med_id, ill_id) VALUES (?, ?)", [id, ill_id])
      end
      redirect('/index')
    end

    # Remove medicine
    post '/admin/meds/remove_med/:id/delete' do | id |
      admin_protected()
      db.execute('DELETE FROM med WHERE medid=?', params['id'])
      redirect('/index')
    end

    # ILLS
    get'/ills/show_ill/:id' do |id|
      @ill = db.execute('SELECT * FROM ill WHERE illid=?', id.to_i).first
      @meds = db.execute('SELECT med.* FROM med INNER JOIN med_ill ON med.medid = med_ill.med_id WHERE med_ill.ill_id = ?', [id.to_i])
      erb(:"/ills/show_ill")
    end

    # New illness
    get '/admin/ills/new_ill' do
      admin_protected()
      @meds = db.execute('SELECT * FROM med')
      erb(:"/admin/ills/new_ill")
    end
    post '/ills/ill' do
      admin_protected()
      name = params[:ill_name]
      desc = params[:ill_desc]
      med_ids = params[:med_ids] || []

      db.execute("INSERT INTO ill (name, description) VALUES (?, ?)", [name, desc])
      ill_id = db.last_insert_row_id

      med_ids.each do |med_id|
        db.execute("INSERT INTO med_ill (med_id, ill_id) VALUES (?, ?)", [med_id, ill_id])
      end
      redirect('/index')
    end

    # Edit illness
    get '/admin/ills/:id/edit_ill' do |id|
      admin_protected()

      @id = params[:id]
      @ill = db.execute('SELECT * FROM ill WHERE illid=?', [id.to_i]).first
      unless @ill
        halt 404, "Illness not found"
      end
      @ills = db.execute('SELECT * FROM ill')
      @meds = db.execute('SELECT * FROM med')

      @med_ills = db.execute('SELECT med.* FROM med INNER JOIN med_ill ON med.medid = med_ill.med_id WHERE med_ill.ill_id = ?', [id.to_i])

      erb(:"/admin/ills/edit_ill")
    end

    post '/admin/ills/:id/edit_ill/update' do |id|
      p @ill
      admin_protected()
      name = params[:ill_name]
      desc = params[:ill_desc]
      med_ids = params[:med_ids] || []

      db.execute("UPDATE ill SET name=?, description=? WHERE illid=?", [name, desc, id])

      db.execute("DELETE FROM med_ill WHERE ill_id = ?", [id])

      med_ids.each do |med_id|
        db.execute("INSERT INTO med_ill (med_id, ill_id) VALUES (?, ?)", [med_id, id])
      end
      redirect('/index')
    end

    # Remove illness
    post '/admin/ills/remove_ill/:id/delete' do | id |
      admin_protected()
      db.execute('DELETE FROM ill WHERE illid=?', params['id'])
      redirect('/index')
    end
end