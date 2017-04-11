require 'active_record'
Dir['./models/*.rb'].each{|file| require_relative file}

ActiveRecord::Base.establish_connection(
	adapter:  'mysql2',
	host: 	  'localhost',
	username: 'root',
	password: '',
	database: 'data_warehouse'
)

puts Actor.count