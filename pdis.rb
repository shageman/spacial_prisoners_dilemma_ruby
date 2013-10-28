# require "colorize"
require 'curses'

class Player1
  def self.move
    "cooperate"
  end

  def self.color
    [0, 0, 255]
  end

  def self.to_s(newly_so)
    # newly_so ? "█".green : "█".blue
    newly_so ? "▒" : "█"
    # newly_so ? "c" : "C"
  end
end

class Player2
  def self.move
    "not cooperate"
  end

  def self.color
    [220, 20, 60]
  end

  def self.to_s(newly_so)
    # newly_so ? "█".yellow : "█".red
    newly_so ? "░" : " "
    # newly_so ? "d" : "D"
  end
end

class Comparison
  def self.compare(move1, move2)
    if move1 == "cooperate" && move2 == "cooperate"
      [1, 1]
    elsif move1 == "not cooperate" && move2 == "cooperate"
      [1.600000000001, 0] #1.6 to 1.6000000000000001
    elsif move1 == "cooperate" && move2 == "not cooperate"
      [0, 1.600000000001]
    else
      [0, 0]
    end
  end
end

class Board
  attr_accessor :config, :width, :height

  def initialize(width, height)
    @width = width
    @height = height
    @config = make_empty_board(nil)
    @old_config = @config
  end

  def random_distribution(p_for_player1, player1, player2)
    Random.new
    @config.each_with_index do |row, i|
      row.each_with_index do |field, j|
        @config[i][j] = rand < p_for_player1 ? player1 : player2
      end
    end
  end

  def move(comparison)
    points_in_round = get_points_of_round(make_empty_board(0))
    reconfigure_board(points_in_round)
  end

  def print_board
    puts "-"*(width+2)
    (0..height-1).to_a.each_with_index do |row, i|
      Kernel.print "|"
      (0..width-1).to_a.each_with_index do |field, j|
        Kernel.print(@config[i][j].to_s(@config[i][j] != @old_config[i][j]))
      end
      puts "|"
    end
    puts "-"*(width+2)
    puts ""
    puts ""
  end

  def string_board
    result = ""
    (0..height-1).to_a.each_with_index do |row, i|
      (0..width-1).to_a.each_with_index do |field, j|
        result << @config[i][j].to_s(@config[i][j] != @old_config[i][j])
      end
      result <<  "\n"
    end
    result
  end

  private

  def make_empty_board(fill_value)
    result = []
    (0..height-1).to_a.each_with_index do |row, i|
      result << []
      (0..width-1).to_a.each_with_index do |field, j|
        result[i] << fill_value
      end
    end
    result
  end

  def get_points_of_round(board_points)
    (0..height-1).to_a.each_with_index do |row, i|
      (0..width-1).to_a.each_with_index do |field, j|
        play_a_round(board_points, [i, j], [i, j+1])
        play_a_round(board_points, [i, j], [i+1, j-1])
        play_a_round(board_points, [i, j], [i+1, j])
        play_a_round(board_points, [i, j], [i+1, j+1])
      end
    end
    board_points
  end

  def play_a_round(board_points, player1_position, player2_position)
    return unless is_on_board?(player1_position) && is_on_board?(player2_position)

    player1 = @config[player1_position.first][player1_position.last]
    player2 = @config[player2_position.first][player2_position.last]

    points_player1, points_player2 = Comparison.compare(player1.move, player2.move)

    board_points[player1_position.first][player1_position.last] += points_player1
    board_points[player2_position.first][player2_position.last] += points_player2
  end

  def is_on_board?(position)
    position.first >= 0 && position.first < @config.length && #row is within rows
        position.last >= 0 && position.last < @config.first.length #column is within columns
  end

  def reconfigure_board(board_points)
    new_config = make_empty_board(nil)

    (0..height-1).to_a.each_with_index do |row, i|
      (0..width-1).to_a.each_with_index do |field, j|
        new_config[i][j] = best_player_in_vicinity(board_points, [i, j])
      end
    end

    @old_config = @config
    @config = new_config
  end

  def best_player_in_vicinity(board_points, position)
    best_players = [@config[position.first][position.last]] # current player is considered best at first 
    max_points = 0
    (position.first-1..position.first+1).to_a.each do |i|
      (position.last-1..position.last+1).to_a.each do |j|
        next unless is_on_board?([i, j])
        if board_points[i][j] > max_points
          best_players = [@config[i][j]]
          max_points = board_points[i][j]
        elsif board_points[i][j] == max_points
          best_players << @config[i][j]
        end
      end
    end    
    best_players.uniq.length == 2 ? @config[position.first][position.last] : best_players.first
  end
end


def init_screen
  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys
  begin
    yield
  ensure
    Curses.close_screen
  end
end

def c_write(line, column, text)
  Curses.setpos(line, column)
  Curses.addstr(text)
end

$b = Board.new(150, 50)
$b.random_distribution(0.8, Player1, Player2)

init_screen do
  c_write 1,0, $b.string_board

  i = 0
  loop do
    c_write 0, 0, "Move: #{i}"
    $b.move(Comparison)
    c_write 1,0, $b.string_board
    i += 1
    case Curses.getch
      when ?q then break  
    end
  end
end

