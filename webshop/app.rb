class App < Sinatra::Base

	enable :sessions

	def set_error(error_message)
		session[:error] = error_message
	end

	def get_error()
		error = session[:error]
		session[:error] = nil
		return error
	end

	get('/') do
		slim(:index)
	end

	get('/login') do
		slim(:login)
	end

	get('/register') do
		slim(:register)
	end

	get('/error') do
		slim(:error)
	end

	get('/notes/create') do
		slim(:create_note)
	end

	get('/notes/:id/edit') do

		if(session[:user_id])
			db = SQLite3::Database.new('db/banan.sqlite')
			db.results_as_hash = true
	
			result = db.execute("SELECT * FROM notes WHERE user_id=?", [session[:user_id]])
			note = result.first

			slim(:edit_note, locals:{note:note})
		else
			redirect('/')
		end
		
	end

	get('/notes') do
		if(session[:user_id])
			db = SQLite3::Database.new('db/banan.sqlite')
			db.results_as_hash = true

			result = db.execute("SELECT * FROM notes WHERE user_id=?", [session[:user_id]])

			slim(:list_notes, locals:{notes:result})
		else
			redirect('/')
		end
	end

	post('/register') do
		db = SQLite3::Database.new('db/banan.sqlite')
		db.results_as_hash = true
		
		username = params["username"]
		password = params["password"]
		password_confirmation = params["confirm_password"]
		
		result = db.execute("SELECT id FROM users WHERE username=?", [username])
		
		if result.empty?
			if password == password_confirmation
				password_digest = BCrypt::Password.create(password)
				
				db.execute("INSERT INTO users(username, password_digest) VALUES (?,?)", [username, password_digest])
				redirect('/')
			else
				set_error("Passwords don't match")
				redirect('/error')
			end
		else
			set_error("Username already exists")
			redirect('/error')
		end
		
	end
	
	
	post('/login') do
		db = SQLite3::Database.new('db/banan.sqlite')
		db.results_as_hash = true
		username = params["username"]
		password = params["password"]
		
		result = db.execute("SELECT id, password_digest FROM users WHERE username=?", [username])

		if result.empty?
			set_error("Invalid Credentials")
			redirect('/error')
		end

		user_id = result.first["id"]
		password_digest = result.first["password_digest"]
		if BCrypt::Password.new(password_digest) == password
			session[:user_id] = user_id
			redirect('/notes')
		else
			set_error("Invalid Credentials")
			redirect('/error')
		end
	end

	post('/logout') do
		session.destroy
		redirect('/')
	end
	
	post('/notes/create') do
		if session[:user_id]
			db = SQLite3::Database.new('db/banan.sqlite')
			db.results_as_hash = true
			content = params["content"]
			
			db.execute("INSERT INTO notes(user_id, content) VALUES (?,?)", [session[:user_id], content])
			redirect('/notes')
		else
			redirect('/')
		end
	end
	
	post('/notes/:id/delete') do
		if session[:user_id]
			note_id = params[:id]
			db = SQLite3::Database.new('db/banan.sqlite')
			db.results_as_hash = true
			result = db.execute("SELECT user_id FROM notes WHERE id=?",[note_id])
			if result.first["user_id"] == session[:user_id]
				db.execute("DELETE FROM notes WHERE id=?",[note_id])
				redirect('/notes')
			end
		else
			redirect('/')
		end
	end
	
	post('/notes/:id/update') do
		if session[:user_id]
			note_id = params[:id]
			new_content = params["content"]

			db = SQLite3::Database.new('db/banan.sqlite')
			db.results_as_hash = true
			result = db.execute("SELECT user_id FROM notes WHERE id=?",[note_id])
			if result.first["user_id"] == session[:user_id]
				db.execute("UPDATE notes SET content=? WHERE id=?",[new_content, note_id])
				redirect('/notes')
			end
		else
			redirect('/')
		end
	end

end           
