#!/usr/bin/env ruby

require 'yaml'
require 'rubygems'
require 'mysql2'
require 'termios'

class Password < String
  def Password.echo(on=true, masked=false)
    term = Termios::getattr( $stdin )

    if on
      term.c_lflag |= ( Termios::ECHO | Termios::ICANON )
    else # off
      term.c_lflag &= ~Termios::ECHO
      term.c_lflag &= ~Termios::ICANON if masked
    end

    Termios::setattr( $stdin, Termios::TCSANOW, term )
  end

  def Password.get(message="Password: ")
    begin
      if $stdin.tty?
	Password.echo false
	print message if message
      end

      pw = Password.new( $stdin.gets || "" )
      pw.chomp!

    ensure
      if $stdin.tty?
	Password.echo true
	print "\n"
      end
    end
  end
end

# Get and check a password from the keyboard
password = Password.get( "Mysql root password: " )

client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => password)

YAML::load(File.open(ARGV[0])).each do |env, config|
   puts "************* Env : #{env}"
   db   = config['database']
   user = config['username']
   pass = config['password']

   sql = "CREATE USER '#{user}'@'localhost' IDENTIFIED BY '#{pass}';"
   puts sql
   client.query(sql)

   sql = "GRANT USAGE ON *.* TO '#{user}'@'localhost' IDENTIFIED BY '#{pass}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
   puts sql
   client.query(sql)

   sql = "CREATE DATABASE IF NOT EXISTS `#{db}` ;"
   puts sql
   client.query(sql)

   sql = "GRANT ALL PRIVILEGES ON `#{db}` . * TO '#{user}'@'localhost';"
   puts sql
   client.query(sql)

end

sql = "FLUSH PRIVILEGES ;"
puts sql
client.query(sql)
