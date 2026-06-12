require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: ENV.fetch('DB_PATH', File.join(__dir__, 'deck_agent.sqlite3'))
)
