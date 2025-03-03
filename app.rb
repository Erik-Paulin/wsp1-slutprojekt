require 'bcrypt'
class App < Sinatra::Base

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/todos.sqlite")
        @db.results_as_hash = true

        return @db
    end

    get '/' do
        erb(:"index")
    end

    configure do
        enable :sessions
        set :session_secret, SecureRandom.hex(64)
    end

    get '/logerror' do
        erb(:"logerror")
    end
      
    get '/logout' do
        p "/logout : Logging out"
        session.clear
        redirect '/'
    end
    post '/login' do
        request_username = params[:username]
        request_plain_password = params[:password]
    
        user = db.execute("SELECT * FROM user WHERE username = ?", request_username).first
    
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
            session[:admin] = 
          redirect '/index'
        else
          status 401
          redirect '/logerror'
        end
    
    end

    get '/admin/:id/edit_med' do |id|
        if session[:admin]
            @id = params[:id]
            @med = db.execute('SELECT * FROM med where id=?', id.to_i).first
            erb(:"/admin/edit_med")
        else
            redirect('/unauthorized')
        end
    end
  
    get '/admin/new_med' do
        if session[:admin]
            erb(:"/admin/new_med")
        else
            redirect('/unauthorized')
        end
    end
    
    get '/admin/:id/edit_ill' do |id|
        if session[:admin]
            @id = params[:id]
            @ill = db.execute('SELECT * FROM ill where id=?', id.to_i).first
            erb(:"/admin/edit_med")
        else
            redirect('/unauthorized')
        end
    end
  
    get '/admin/new_ill' do
        if session[:admin]
            erb(:"/admin/new_ill")
        else
            redirect('/unauthorized')
        end
    end

    post '/admin/:id/update_med' do |id|
        if session[:admin]
            name = params[:med_name]
            desc = params[:med_desc]

            db.execute("UPDATE med SET name=?, description=? WHERE id=?", [name, desc, id])
            redirect('/index')
        else
            redirect('/unauthorized')
        end
    end
    post '/admin/:id/update_ill' do |id|
        if session[:admin]
            name = params[:ill_name]
            desc = params[:ill_desc]

            db.execute("UPDATE ill SET name=?, description=? WHERE id=?", [name, desc, id])
            redirect('/index')
        else
            redirect('/unauthorized')
        end
    end

end
