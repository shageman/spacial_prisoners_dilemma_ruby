class Player1
  def self.move
    "cooperate"
  end

  def self.color
    [0, 0, 255]
  end
end

class Player2
  def self.move
    "not cooperate"
  end

  def self.color
    [220, 20, 60]
  end
end

class Comparison
  def self.compare(move1, move2)
    if move1 == "cooperate" && move2 == "cooperate"
      [1, 1]
    elsif move1 == "not cooperate" && move2 == "cooperate"
      [0, 3]
    elsif move1 == "cooperate" && move2 == "not cooperate"
      [3, 0]
    else
      [2, 2]
    end
  end
end

class Board
  attr_accessor :config, :width, :height

  def initialize(width, height)
    @width = width
    @height = height
    @config = make_empty_board(nil)
  end

  def random_distribution(*players)
    @config.each_with_index do |row, i|
      row.each_with_index do |field, j|
        @config[i][j] = players.sample
      end
    end
  end

  def numbers_for_players
    result = {}
    @config.each_with_index do |row, i|
      row.each_with_index do |field, j|
        result[@config[i][j]] = 0 unless result[@config[i][j]]
        result[@config[i][j]] += 1
      end
    end
    result
  end

  def move(comparison)
    points_in_round = get_points_of_round(make_empty_board(0))
    reconfigure_board(points_in_round)
  end

  private

  def make_empty_board(fill_value)
    result = []
    (1..height).to_a.each_with_index do |row, i|
      result << []
      (1..width).to_a.each_with_index do |field, j|
        result[i] << fill_value
      end
    end
    result
  end

  def get_points_of_round(board_points)
    (1..height).to_a.each_with_index do |row, i|
      (1..width).to_a.each_with_index do |field, j|
        #play these against each other (right and down is what I play against)
        #i  , j+1
        #i+1, j-1
        #i+1, j
        #i+1, j+1

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

    player1 = @config[player1_position.first-1][player1_position.last-1]
    player2 = @config[player2_position.first-1][player2_position.last-1]

    points_player1, points_player2 = Comparison.compare(player1.move, player2.move)

    board_points[player1_position.first-1][player1_position.last-1] += points_player1
    board_points[player2_position.first-1][player2_position.last-1] += points_player2
  end

  def is_on_board?(position)
    position.first >= 0 && position.first < @config.length && #row is within rows
        position.last >= 0 && position.last < @config.first.length #column is within columns
  end

  def reconfigure_board(board_points)
    new_config = make_empty_board(nil)

    (1..height).to_a.each_with_index do |row, i|
      (1..width).to_a.each_with_index do |field, j|
        new_config[i][j] = best_player_in_vicinity(board_points, [i, j])
      end
    end

    @config = new_config
  end

  def best_player_in_vicinity(board_points, position)
    best_position_points = 99999
    best_position = nil
    (position.first-1..position.first+1).to_a.each do |i|
      (position.last-1..position.last+1).to_a.each do |j|
        next unless is_on_board?([i, j])
        best_position = [i, j] if board_points[i][j] < best_position_points
      end
    end
    @config[best_position.first][best_position.last]
  end
end


$b = Board.new(10, 20)
$b.random_distribution(Player1, Player2)


Shoes.app(width: $b.width*10, height: $b.height*10) do
  def paint_the_board
    (1..($b.height)).to_a.each_with_index do |row, i|
      (1..($b.width)).to_a.each_with_index do |field, j|
        fill rgb(*$b.config[i][j].color)
        rect(left: j * 10, top: i * 10, width: 10)
      end
    end
  end

  animate(10) do |frame|
    if frame < 20
      $b.move(Comparison)
      paint_the_board
    end
  end
end


