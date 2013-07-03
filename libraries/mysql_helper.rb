module MysqlHelper
  # Check if a mysql database exists
  def self.mysql_db_exists?(credentials, db)
    require 'mysql'
    conn = ::Mysql.connect(credentials[:host], credentials[:username], credentials[:password], db)
    conn.close
    true
  rescue Mysql::Error => e
    if e.message =~ /Unknown database/
      return false
    else
      raise(e)
    end
  end

  # Make sure mysql has a user with +username+ with all privileges on localhost.
  def self.create_superuser(credentials, username, password)
    require 'mysql'
    conn = ::Mysql.connect(credentials[:host], credentials[:username], credentials[:password])
    conn.query("GRANT ALL ON *.* TO '#{username}'@'localhost' IDENTIFIED BY '#{password}'")
  ensure
    conn.close if conn
  end
end
