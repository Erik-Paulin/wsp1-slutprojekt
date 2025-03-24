require 'bcrypt'
class App < Sinatra::Base

    helpers do 
        def admin_protected()
            redirect('/unauthorized') if session[:user_id].nil?
            user = db.execute('SELECT is_admin FROM users WHERE id=?', [session[:user_id]])
            redirect('/unauthorized') if !user['is_admin']
        end
        def user_protected()
            redirect('/unauthorized') if session[:user_id].nil?
        end

    end

    def db
        return @db if @db

        @db = SQLite3::Database.new("db/drugs.sqlite")
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
            redirect '/index'
        else
            status 401
            redirect '/logerror'
        end
    
    end
    get '/user/prescript' do
        user_protected()

        user_med_id = session[:user_id]
        @meds = db.execute('SELECT med FROM user_med WHERE user_id=?'[user_med_id])

        erb(:"/user/prescript")
    end

    get '/admin/:id/edit_med' do |id|
        admin_protected()

        @id = params[:id]
        @med = db.execute('SELECT * FROM med WHERE id=?', [id.to_i]).first
        erb(:"/admin/edit_med")
    end
  
    get '/admin/new_med' do
        admin_protected()
        
        erb(:"/admin/new_med")   
    end
    
    get '/admin/:id/edit_ill' do |id|
        admin_protected()

        @id = params[:id]
        @ill = db.execute('SELECT * FROM ill WHERE id=?', id.to_i).first
        erb(:"/admin/edit_med")
    end
  
    get '/admin/new_ill' do
        admin_protected()

        erb(:"/admin/new_ill")
    end

    post '/admin/:id/update_med' do |id|
        admin_protected()
        
        name = params[:med_name]
        desc = params[:med_desc]
        
        db.execute("UPDATE med SET name=?, description=? WHERE id=?", [name, desc, id])
        redirect('/index')
        
    end
    post '/admin/:id/update_ill' do |id|
        admin_protected()
        
        name = params[:ill_name]
        desc = params[:ill_desc]
        
        db.execute("UPDATE ill SET name=?, description=? WHERE id=?", [name, desc, id])
        redirect('/index')
    end

end
