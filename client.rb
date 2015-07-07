#!/usr/bin/env ruby -w

# We need socket for TCP sockets
require 'socket'

# Create a new class that will contain all the code for our client
class Client
	def initialize(server)
		# Create the required variables
		@server = server
		@request = nil
		@response = nil
		# create the regex statement for server messages.
		@server_message_regex = /^<server-message>:/
		# Start a new thread for start and listen actions
		listen
		send
		# thread.join causes the main thread to wait until the children
		# haved died or exited before it exits itself.
		@request.join
		@response.join
	end

	def send
		# Start a new thread that will listen for messages from the server.
		@request = Thread.new do
			loop {
				# Gets the messages from the TCP socket.
				msg = @server.gets.chomp
				# Filter messages for server control messages.
				listen_server_message(msg)
				# Displays the message.
				puts "#{msg}"
			}
		end
	end
	
	#listen for messages from the user
	def listen
		# Before starting we need to get the users name from the user.
		puts "Enter your username:"
		# Start a new thread that will wait for user input and then
		# send it onto the server.
		@response = Thread.new do
			msg = $stdin.gets.chomp
			@server.puts( msg )
			loop {
				# Gets input from the user.
				print "> "
				msg = $stdin.gets.chomp
				# Check if the message is a server control message crafted by the user.
				# Send error message to the user if it is. 
				# Else send the message to the server for processing.
				if (msg =~ @server_message_regex )
					puts "Server messages are not permitted on the client!"
				else
					@server.puts( msg )
				end
			}
		end
	end

	def listen_server_message(msg)
		# This function will test the messages for server control messages
		# and pass it on to the contol parser if it is else do nothing if its nothing.
		# By doing nothing we will let the display function do its job which would be next.
		if ( msg =~ @server_message_regex )
			message_parser(msg)
		end
	end

	def message_parser(msg)
		# Server control messages have a special format.
		# <server-message>:ControlMessage, we need to read the section after the :
		# So we split the message on the : and grab the second half of the message
		srv_msg = msg.split(":")[1]
		# This case statement will look for the control messages.
		case srv_msg
		when "CloseConnection"
			# Close the connection of the client.
			puts "!! Got CloseConnection from the server"
			exit 0 
		else
			# Default message if the message is not in the case list.
			puts "Got server message, though not recognized"
			puts "#{srv_msg}"
		end
		# Destroy the msg as it contained a server message that has now been consumed.
		return msg = ""
	end
end

#Create a new TCP Socket to the server
server = TCPSocket.open("localhost", 2000)
# Start the client class.
Client.new(server)