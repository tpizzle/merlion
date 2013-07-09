require 'colorize'
class Merlion
	module Util
		ActionMap = {
			'f' => :check_or_fold,
			'c' => :call,
			'r' => :bet_raise,
			'k' => :check_or_fold
		}
		# When talking to the Meerkat bridge, 'f' is check or fold
		InvertedActionMap = ActionMap.invert
		InvertedActionMap.merge!({
			check_or_fold: 'f',
		})

		#  Simple helper to ansi-colour card strings on a terminal
		def render_cards(str)
			return '' unless str
			str.scan(/../).map do |cards|
				cards =~ /d|h/ ? cards.red.on_white : cards.black.on_white
			end.join('')
		end

		# Converts a single-letter action into a symbol
		def action(str)
			act = ActionMap[str]
			unless act
				raise "Unknown action '#{str}'"
			end
			return act
		end

		# Converts an action symbol into a single letter
		def action_str(sym)
			act = InvertedActionMap[sym]
			unless act
				raise "Unknown action '#{sym}'"
			end
			return act
		end

	end
end
