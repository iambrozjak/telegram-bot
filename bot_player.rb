require 'telegram/bot'
require_relative 'game1'

class TelegramBot
  def initialize
    @game = nil
  end

  def run
    token = '6717303833:AAHFBvY7TggGXDAbdxUgcuBnKzSjHFlg-Oc'
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen { |message| handle_message(bot, message) }
    end
  end

  private

  def handle_message(bot, message)
    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_callback(bot, message)
    when Telegram::Bot::Types::Message
      handle_text_message(bot, message)
    end
  end

  def handle_callback(bot, message)
    case message.data
    when 'new_game'
      start_new_game(bot, message.message)
    else
      if @game
        x, y = message.data.split(',').map(&:to_i)
        @game.make_move(x, y)
        game_status = @game.game_over?
        if game_status
          handle_game_over(bot, message, game_status)
        end
      end
    end
  end

  def handle_text_message(bot, message)
    case message.text
    when '/start'
      bot.api.sendMessage(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}!")
      bot.api.send_message(chat_id: message.chat.id, text: "I'm tic-tac-toe bot.")
      bot.api.send_message(chat_id: message.chat.id, text: "If your want to play - make your choise")
      start_new_game(bot, message)
    when '/stop'
      @game = nil
      bot.api.send_message(chat_id: message.chat.id, text: 'Game stopped.')
    end
  end

  def determine_winner
    current_player = @game.instance_variable_get(:@current_player)
    player = @game.instance_variable_get(:@player)
    opponent = @game.instance_variable_get(:@opponent)
    current_player == player ? opponent : player
  end

  def handle_game_over(bot, message, game_status)
    if game_status == :draw
      bot.api.send_message(chat_id: message.message.chat.id, text: "Game over. It's a draw.")
    else
      winner = determine_winner
      bot.api.send_message(chat_id: message.message.chat.id, text: "Game over. The winner is #{winner}.")
    end
    @game = nil
  end

  def start_new_game(bot, message)
    @game = Game.new(bot, message)
    @game.play
  end
end
