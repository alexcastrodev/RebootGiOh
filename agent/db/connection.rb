require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     ENV.fetch('DB_HOST', 'db'),
  port:     ENV.fetch('DB_PORT', 3306).to_i,
  username: ENV.fetch('DB_USER', 'bot'),
  password: ENV.fetch('DB_PASS', 'bot'),
  database: ENV.fetch('DB_NAME', 'botdb')
)
