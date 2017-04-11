



class Ruby
  attr_reader :x, :y
WindowWidth = 1024
attr_reader :type
  def initialize(type)
    @type = type
    @image = if type == :ruby_up
#On a deux sortes de ruby : les noirs et les classics.
               Gosu::Image.new('images/ruby2.png')
             elsif type == :ruby_down
               Gosu::Image.new('images/ruby.png')
             end
# La vitesse de deplacement des ruby est variable
    @velocity = Gosu::random(0.8, 0.8)

    #On s'assure que les ruby restent bien dans la fenêtre
    @x = rand * (WindowWidth - @image.width)
    # Les ruby apparraissent aléatoirement dans la fenêtre
    @y = rand * (768 - @image.width)


  end

  def update
    @y += @velocity
  end

  def draw
    @image.draw(@x, @y, 1)
  end

end


# Gestion de l'affichage du score
class UI

  def initialize
    @font = Gosu::Font.new(35, name: "front/orange juice 2.0.ttf")
  end

  def draw(score:)
    @font.draw("Score: #{score}", 10, 700, 3, 1.0, 1.0, 0xff_ffff00)
  end

end




class GameWindow < Hasu::Window
  SPRITE_SIZE = 128
  WINDOW_X = 1024
  WINDOW_Y = 768
attr_reader :score
  def initialize

    @score = 0
    super(WINDOW_X, WINDOW_Y, false)
    @ui = UI.new

    @background_sprite = Gosu::Image.new(self, 'images/background.png', true)
    @koala_sprite = Gosu::Image.new(self, 'images/koala.png', true)
    @enemy_sprite = Gosu::Image.new(self, 'images/enemy.png', true)
    @enemy_sprite2 = Gosu::Image.new(self, 'images/enemy2.png', true)
    @flag_sprite = Gosu::Image.new(self, 'images/flag.png', true)
    @font = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @flag = {x: WINDOW_X - SPRITE_SIZE, y: WINDOW_Y - SPRITE_SIZE}
    @sound_collect = Gosu::Sample.new("musics/GetRuby2.wav")
    @sound_Nocollect = Gosu::Sample.new("musics/NoGetRuby.wav")
    @music = Gosu::Song.new(self, "musics/koala.wav")
    @lose_sprite = Gosu::Image.new(self, 'images/flag.png', true)
    @items = []



    reset
  end

  def update
#on fera apparaitre àà chaque fois environ 5 ruby
# avec plus de chance d'obtenir les ruby noirs
    unless @items.size >= 3
      r = rand
      if r < 0.300
        @items.push(Ruby.new(:ruby_up))
      elsif r < 0.500
        @items.push(Ruby.new(:ruby_down))
      end
    end
    @disparution = rand(10..200)
    @items.each(&:update)
    @items.reject! {|item| item.y > WINDOW_Y }
    collect_rubys(@items)

    @player[:x] += @speed if button_down?(Gosu::Button::KbRight)
    @player[:x] -= @speed if button_down?(Gosu::Button::KbLeft)
    @player[:y] += @speed if button_down?(Gosu::Button::KbDown)
    @player[:y] -= @speed if button_down?(Gosu::Button::KbUp)
    @player[:x] = normalize(@player[:x], WINDOW_X - SPRITE_SIZE)
    @player[:y] = normalize(@player[:y], WINDOW_Y - SPRITE_SIZE)
    handle_enemies
    handle_quit
    if winning?
      reinit
    end
    if loosing?

      reset
    end
  end

def lose
 @lose_sprite = {x: WINDOW_X/2, y: WINDOW_Y/2}

end
  def draw

    @font.draw("Level #{@enemies.length}", WINDOW_X - 100, 10, 3, 1.0, 1.0, Gosu::Color::GREEN)

    @koala_sprite.draw(@player[:x], @player[:y], 2)
    @enemies.each do |enemy|
      @enemy_sprite.draw(enemy[:x], enemy[:y], 2)
      #
  #  @enemy_sprite2.draw(enemy2[:x], enemy2[:y], 2)

      #@koala_sprite2.draw(@player[:x], @player[:y], 2)
      #@enemies2.each do |enemy2|
      #  @enemy_sprite2.draw(enemy[:x], enemy[:y], 2)

    end
    @flag_sprite.draw(@flag[:x], @flag[:y], 1)
    (0..8).each do |x|
      (0..8).each do |y|
        @background_sprite.draw(x * SPRITE_SIZE, y * SPRITE_SIZE, 0)
        @items.each(&:draw)
      end
    end
    @ui.draw(score: @score)
  end
# gestion du comportement du jeu dans le ramassage des rubys
def collision(type)
    case type
    when :ruby_down
      @score += 50
      @sound_collect.play
    when :ruby_up
     @score -= 50
     @sound_Nocollect.play
    end

    true
  end

#collision à utiliser pour le ramassage des ruby
# chaque ramassage donne 10 points
def collect_rubys(rubys)
    rubys.reject! do |ruby|
      dist_x = @player[:x] - ruby.x
      dist_y = @player[:y] - ruby.y
      dist = Math.sqrt(dist_x * dist_x + dist_y * dist_y)
      # On considère une proximité de 30 pixel
      if dist < 60 then
       collision(ruby.type)
        true
      else
        false
      end
    end
  end


  private

  def reset
    @high_score = 0
    @enemies = []
    @enemies2 = []
    @speed = 10
    @music.stop
    @score = 0
    #@music.play
    reinit
  end

  def reinit
    @speed += 2
    @player = {x: 0, y: 400}
    @enemies.push({x: 500 + rand(100), y: 200 + rand(300)})
    @enemies2.push({x: 100 + rand(10), y: 20 + rand(30)})
    high_score
  end

  def high_score
    unless File.exist?('hiscore')
      File.new('hiscore', 'w')
    end
    @new_high_score = [@enemies.count, File.read('hiscore').to_i].max
    File.write('hiscore', @new_high_score)
  end

  def collision?(a, b)
    (a[:x] - b[:x]).abs < SPRITE_SIZE / 2 &&
    (a[:y] - b[:y]).abs < SPRITE_SIZE / 2
  end


  def loosing?
    @enemies.any? do |enemy|
      collision?(@player, enemy)
    end
  end

  def winning?
    collision?(@player, @flag)
  end

#son (beep) joué à chaque ramassage de ruby


  def random_mouvement
    (rand(3) - 1)
  end

  def normalize(v, max)
    if v < 0
      0
    elsif v > max
      max
    else
      v
    end
  end

  def handle_quit
    if button_down? Gosu::KbEscape
      close
    end
  end

  def handle_enemies
    @enemies = @enemies.map do |enemy|
      enemy[:timer] ||= 0
      if enemy[:timer] == 0
        enemy[:result_x] = random_mouvement
        enemy[:result_y] = random_mouvement
        enemy[:timer] = 50 + rand(50)
      end
      enemy[:timer] -= 1

      new_enemy = enemy.dup
      new_enemy[:x] += new_enemy[:result_x] * @speed
      new_enemy[:y] += new_enemy[:result_y] * @speed
      new_enemy[:x] = normalize(new_enemy[:x], WINDOW_X - SPRITE_SIZE)
      new_enemy[:y] = normalize(new_enemy[:y], WINDOW_Y - SPRITE_SIZE)
      unless collision?(new_enemy, @flag)
        enemy = new_enemy
      end
      enemy
    end
  end
end
