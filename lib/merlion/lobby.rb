require 'eventmachine'
require 'merlion/game/local'
require 'merlion/log'

class Merlion
	class Lobby
		include Merlion::Log
		attr_accessor :games

		def initialize
			@games = []
		end

		def create_game
			game = Merlion::Game::Local.new({ num_players: 3, stacks: [200,200,200] })
			game.add_player({class: Merlion::Bot})
			game.add_player({class: Merlion::Bot})
			game.start
			return game
		end

		def add_player_to_game(game, conn)
			new_player = games[game].add_player
			# remember which player is on this connection
			conn.player = new_player
			# set the connection for the player, so they can write messages
			new_player.conn = conn
			# consider starting the hand
			games[game].player_added
		end

		def remove_player_from_game(game, conn)
			conn.player = nil
			games[game].remove_player
		end

		class Connection < EM::Connection
			include Merlion::Log
			attr_accessor :lobby, :player

			def initialize(lobby)
				self.lobby = lobby
			end

			def receive_data(data)
				process_line(data)
			end

			def process_line(line)
				line.chomp!
				debug("Got: #{line}")
				if self.player
					self.player.line_received(line)
				else
					lobby.add_player_to_game(0, self)
					puts "got some line from player: #{line}"
				end
			end
		end

		class EchoServer < Connection
		end

		class MyKeyboardHandler < Connection
			include EM::Protocols::LineText2

			def receive_line (data)
				process_line(data)
			end

			def send_data(data)
				puts data
			end
		end

		def start
			EventMachine.run do
				games[0] = create_game
				EventMachine.start_server("0.0.0.0", 10000, EchoServer, self)
				EM.open_keyboard(MyKeyboardHandler, self)
			end
		end

	end
end
