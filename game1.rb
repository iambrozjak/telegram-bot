require 'telegram/bot'

class Game
  attr_reader :board, :current_player

  def initialize(bot, message)
    @board = Array.new(3) { Array.new(3, '-') }
    @message = message
    @bot = bot
    @player = '✖️'
    @opponent = '⭕'
    @current_player = @player
  end

  def play
    print_board
  end

  def make_move(x, y)
    if valid_move?(x, y)
      @board[x][y] = @current_player
      print_board
      switch_player
      computer_move unless game_over?
    else
      send_message("Invalid move. Please try again.")
    end
  end

  def computer_move
    empty_cells = find_empty_cells

    if empty_cells.any?
      move = empty_cells.sample
      @board[move[0]][move[1]] = @current_player
      print_board
      switch_player
    end
  end

  def game_over?
    winner = check_winner
    return true if [:player, :opponent].include?(winner)
    return :draw if winner == :draw

    false
  end

  private

  def print_board
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: @board.map.with_index do |row, i|
        row.map.with_index do |cell, j|
          Telegram::Bot::Types::InlineKeyboardButton.new(text: cell, callback_data: "#{i},#{j}")
        end
      end
    )
    send_message("Player's #{@current_player} turn", markup)
  end

  def switch_player
    @current_player = (@current_player == @player) ? @opponent : @player
  end

  def valid_move?(x, y)
    (0..2).cover?(x) && (0..2).cover?(y) && @board[x][y] == '-'
  end

  def find_empty_cells
    empty_cells = []

    @board.each_with_index do |row, i|
      row.each_with_index do |cell, j|
        empty_cells << [i, j] if cell == '-'
      end
    end

    empty_cells
  end

  def check_winner
    winning_combinations = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], # Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], # Columns
      [0, 4, 8], [2, 4, 6]             # Diagonals
    ]

    winning_combinations.each do |combo|
      return :player if combo.all? { |i| @board.flatten[i] == @player }
      return :opponent if combo.all? { |i| @board.flatten[i] == @opponent }
    end

    return :draw unless @board.flatten.include?('-')

    nil
  end

  def send_message(text, markup = nil)
    @bot.api.send_message(chat_id: @message.chat.id, text: text, reply_markup: markup)
  end
end
