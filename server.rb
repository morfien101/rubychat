#!/usr/bin/env ruby -w

# We need socket for TCP sockets
require 'socket'

# Create a new class that will contain all the code for the server.
class Server
	def initialize(port, ip)
		# Create all the required variables.
		@server = TCPServer.open(ip, port)
		@connections = Hash.new
		@clients = Hash.new
		# Set them as needed.
		@connections[:server] = @server
		@connections[:clients] = @clients
		@server_message_regex = /^<server-message>:/
		# Start the server loops
		run
	end

	def run 
		loop {
			# Start a new thread for every new connection to the server.
			# Client messages do not count as a connection.
			# They are TCP Established connections.
			Thread.start(@server.accept) do |client|
				#converts the username to a symbol with out the trailing new line
				nick_name = client.gets.chomp.to_sym
				# Prints some logging to the Server console.
				puts @connections[:clients]
				# Checks to see if the username is already taken
				@connections[:clients].each do |other_name, other_client|
					if nick_name == other_name || client == other_client
						puts "kill thread for new user: #{nick_name}"
						# Send a error message to the new connection.
						client.puts "This username is already in use."
						# Send a server control message to close the client gracefully.
						client.puts "<server-message>:CloseConnection"
						# Kill the thread that handled the connection.
						Thread.kill self
					end
				end
				# Adds the client to a list of knowen clients.
				@connections[:clients][nick_name] = client
				# Prints some more logging
				puts "#{nick_name} #{client} has joined the server."
				# sends a welcome message.
				client.puts "Connection established, Thank you for joining."
				# Starts a new thread to listen for messages from this client.
				listen_user_messages(nick_name, client)
			end
		}
	end

	def listen_user_messages(username, client)
		# Starts an endless loop to check for messages
		loop {
			# get messages from this tcp socket
			msg = client.gets.chomp
			# check leaked server sent messages from clients. 
			# Stop users hacking the server.
			msg = scan_server_message(msg)
			# Check for special feature messages
			# Only whispers have been implemented.
			case msg
			# Regex to match "/w <username> ".
			when /^\/[Ww]\s\w+/
				# Break up the words in the message
				msg = msg.split(" ")
				# Get the username for the recipient.
				whisper_to = msg[1]
				# Join the message back up.
				msg_body = msg[2..-1].join(" ")
				# Send the message only to the recipient. 
				# Add in "Whispered" to show it is a whisper.
				@connections[:clients][whisper_to.to_sym].puts "#{username.to_s} Wispered: #{msg_body}"	
			else
				# Send all other messages to all users.
				@connections[:clients].each do |other_name, other_client|
					# Send to eveyone expect for myself
					unless other_name == username
						puts "#{username.to_s}: #{msg}"
						other_client.puts "#{username.to_s}: #{msg}"
					end
				end
			end
		}
	end

	def scan_server_message(msg)
		# Scan the messages for all messages that start with "<server-message>:"
		# Drop them as clients should not be able to send server control messages.
		if ( msg =~ @server_message_regex )
			msg = "Server: Message dropped for security"
		end
		# Returns the original message if no server message was found.
		# Returns a error message if it was found.
		return msg
	end
end

# Start a new instace of the server.l
server = Server.new(2000, "localhost")
# Start the loops that run the server service.
server.run