require 'merlion/log'
require 'merlion/lobby'
require 'merlion/lobby/connhelper'
require 'em-websocket'
require 'eventmachine'
require 'singleton'
require 'json'

class Merlion
	class Lobby
		# A client that communicates with JSON (eg. websocket)
		class JSONClient
			include Merlion::Lobby::ConnHelper
			def write_hand_started(p)
				write(p.game.to_hash, 'hand_started');
			end

			def write_state_changed(p)
				hash = p.game.to_hash
				hash[:last_player] = p.game.last_player.to_hash
				write(hash, 'state_changed')
			end

			def get_games_list
				return lobby.get_games
			end

			def join_message(player)
				game_info = player.game.to_hash_full
				game_info[:hero_seat] = player.seat
				return game_info
			end

			def create_error(e)
				return {
					type: 'error',
					message: e.message
				}
			end
		end
		class WebSocketConnection < JSONClient
			def initialize(ws, lobby)
				@ws = ws
				@lobby = lobby
			end
			
			# Send a message to the wbsocket
			# @param msg [Object] The JSON data to send
			# @param channel [String] This maps to a websocket 'event listener' on the client side
			def write(msg, channel)
				payload = {
					merlion: [channel, msg]
				}.to_json
				@ws.send(payload)
			end	
		end
	end
end


class Merlion
	class Lobby
		# The main EventMachine websocket connection handler. Simply routes messages to the client.
		class WebSocketServer
			include Singleton
			include Merlion::Log
			attr_reader :lobby

			def init(lobby)
				@lobby = lobby
				@ws_conns = {}
			end

			def start_server
				EM::WebSocket.start(:host => '0.0.0.0', :port => 11111) do |ws|
					ws.onopen do |handshake|
						@ws_conns[ws.object_id] = Merlion::Lobby::WebSocketConnection.new(ws, self.lobby)
					end
					ws.onmessage do |msg|
						debug("<<< #{ws.object_id} #{msg}")
						obj = @ws_conns[ws.object_id]
						obj.handle(msg)
					end
				end
			end
		end
	end
end

