# encoding: UTF-8
#
# View: View Interface tExt Widgets
# By beoran, 2012. Licenced under the ZLIB license. 
# 
# A tiny library for text-based full screen applications using Curses 
# Requires Ruby 1.9.3. 
#
#

require 'io/console'
require 'curses'


# A view is the toplevel object in View, it's a rectangular window 
# that can display text and receive text input, etc.
class View
  
  # Returns the width of the console screen in text cells.
  def self.screen_w
    return Curses.cols
  end
  
  # Returns the height of the console screen in text cells.
  def self.screen_h
    return Curses.lines
  end
    
  # Basic color names are taken from HTML: 
  # aqua, black, blue, fuchsia, gray, green, lime, maroon, navy, 
  # olive, purple, red, silver, teal, white, and yellow
  # aqua     #00FFFF    lime     #00FF00    silver   #C0C0C0
  # black    #000000    maroon   #800000    teal     #008080
  # blue     #0000FF    navy     #000080    white    #FFFFFF
  # fuchsia  #FF00FF    olive    #808000    yellow   #FFFF00
  # gray     #808080    purple   #800080
  # green    #008000    red      #FF0000

  DIM_COLORS = { 
    :black    => Curses::COLOR_BLACK  ,
    :navy     => Curses::COLOR_BLUE   ,
    :teal     => Curses::COLOR_CYAN   ,
    :green    => Curses::COLOR_GREEN  ,
    :purple   => Curses::COLOR_MAGENTA,
    :maroon   => Curses::COLOR_RED    ,
    :silver   => Curses::COLOR_WHITE  ,
    :olive    => Curses::COLOR_YELLOW ,
  }

  BRIGHT_FOR_DIM = {
    :black    => :gray,
    :navy     => :blue,
    :teal     => :cyan,
    :green    => :lime,
    :purple   => :fuchsia,
    :maroon   => :red,
    :silver   => :white,
    :olive    => :yellow,
  }

  # Returns an integer that encodes the Curses attribute to use 
  # for the givencolor pair combination.
  # May return nil if the colors are unknown. color names bust be the 
  # 16 basic HTML color names as symbols in lower case. :default
  # is allowed for the background.
  def self.color_by_name(fg_name = :white, bg_name = :default) 
    @colors_by_name ||= {}
    aid = @colors_by_name[bg_name]
    return nil unless aid
    return aid[fg_name]
  end
  
  # Sets up the color pairs and colors for this screen
  def self.init_colors
    Curses.start_color
    Curses.use_default_colors
    # @colors_by_name stores colors by name in a double hash.
    @colors_by_name = {}
    @color_count = 0
    for bg_name, bg_value in DIM_COLORS do
      @colors_by_name[bg_name] ||= {}
      for fg_name, fg_value in DIM_COLORS do
        Curses.init_pair(@color_count, fg_value, bg_value)
        # Dim color
        @colors_by_name[bg_name][fg_name] = Curses.color_pair(@color_count)
        # Bright color
        @colors_by_name[bg_name][BRIGHT_FOR_DIM[fg_name]] = 
          Curses.color_pair(@color_count) | Curses::A_BOLD
        # Increase color count.
        @color_count += 1
      end
    end
    # set up default background color.
    @colors_by_name[:default] = @colors_by_name[:black]
  end
  
  # Should be called before using View. Initializes Curses. Auto-installs
  # View.done to be called on end of program.
  def self.init
    @init ||= false
    return true if @init
    Curses.init_screen
    at_exit { self.done }
    self.init_colors
    # enable arrow keys
    Curses.stdscr.keypad(true)
    @init = true
  end
  
  # Deinitializes View and Curses.
  def self.done
    Curses.close_screen
    @init = false
  end
  
  
  # Constructor for view.
  def initialize(x = 0, y = 0, w = nil, h = nil, parent = nil)
    @parent   = parent
    @kids     = []
    if @parent
      w ||= self.class.screen_w
      h ||= self.class.screen_h
      @window = Curses::Window.new(h, w, y, x) 
    else
      @window = Curses.stdscr
    end
    @heading = nil
    # Allow easier initialization though a block.
    if block_given?
      yield self
    end
  end
  
   # Creates a new view as the child of the current view
  def view(x = 0, y = 0, w = nil, h = nil, &block)
    child = self.class.new(x, y, w, h, self, &block)
    return add_child(child)
  end
  
  # Creates a new view with the given class as the child of the current view
  def view_of(klass, x = 0, y = 0, w = nil, h = nil, &block)
    child = klass.new(x, y, w, h, self, &block)
    return add_child(child)
  end
  
  def add_child(child)
    @kids << child
    return child
  end
  
  
  # can set or read the heading
  attr_accessor :heading
  # can read the curses window
  attr_reader   :window
  
  
  def w
    return @window.maxx
  end
  
  def h
    return @window.maxy
  end
  
  def x
    return @window.begx
  end
  
  def y
    return @window.begy
  end
  
  # Moves cursor to given position. Position is relative to view.
  def at(xx, yy)
    return @window.setpos(yy, xx)
  end
  
  # Writes a string at the given position.
  def strat(xx, yy, ss)
    at(xx,yy)
    return addstr(ss)
  end
  
  # Writes a string at the current cursor position.
  def addstr(ss)
    return @window.addstr(ss)
  end
    
  
  # Writes a character. Doesn't work for UTF-8, use strat in stead.
  def chat(xx, yy, s)
    at(xx,yy)
    return @window.addch(s)
  end
  
    
  # Draws a box around the view.
  def draw_box
    strat 0, 0, "┌" + ("─" * (self.w - 2)) + "┐"
    reps = self.h - 2
    reps.times do | i |
      strat(0, i + 1, "│")
      strat(self.w - 1, i + 1, "│")
    end
    strat 0, self.h - 1, "└" + ("─" * (self.w - 2)) + "┘"
  end
  
  # Draws the heading, if any, centered.
  def draw_heading
    return unless @heading
    xpos = (self.w - @heading.size) / 2
    xpos = 0 if xpos < 0
    strat(xpos, 0, @heading)
  end
  
  # Draws the children.
  def draw_children
    for child in @kids do
      child.draw
    end
  end
  
  # draws the view itself, without it's children
  # override this!
  def draw_self
  end
  
  # Draws the whole view and it's children
  # Normally you don't need to override this.
  def draw
    draw_box
    draw_heading
    draw_self
    draw_children
  end
  
  # Updates the view's children
  def update_children
    for child in @kids do
      Curses.flash
      child.update
    end
  end
  
  # Updates the view and displays it on the console
  def update
    @window.noutrefresh
    update_children
    # toplevel only: update whole screen
    if @parent == nil
      Curses.doupdate
    end
  end
  
  
  # A one-line status display.
  class Status < View
    
    def initialize(x = 0, y = 0, w = nil, h = nil, parent = nil)
      # call super constructor 
      super
      self.ok
    end
    
    # Sets an error message in the view.
    def error(message)
      @status = :error
      @text   = message
    end
    
    # Sets the view back to OK and shows the message.
    def ok(message= "OK")
      @status = :ok
      @text   = message
    end
    
    
    # overrides View draw_self
    def draw_self
      attr = View.color_by_name(:green) 
      attr = View.color_by_name(:red) if @status != :ok
      @window.attron(attr) do
        at(1,1)
        @window.clrtoeol()
        addstr(@text)
      end
    end
    
    
  end
  
  
    # A one-line input field.
  class Input < View
    def initialize(x = 0, y = 0, w = nil, h = nil, parent = nil)
      # call super constructor 
      super
      @prompt = ">"
      @input  = "none"
    end
    
    # Accessor for the read input
    attr_accessor :input
    
    # Accessor for the prompt
    attr_accessor :prompt
    
    # Reads a line of input, blocking.
    def getstr
      @input = @window.getstr
      return @input
    end
      
    
    
    
    # overrides View draw_self
    def draw_self
      attr = View.color_by_name(:yellow)
      @window.attron(attr) do
        at(1,1)
        @window.clrtoeol()
        addstr(@prompt)
      end
      attr = View.color_by_name(:white)
      @window.attron(attr) do
        addstr("")
      end
    end
    
    
  end
end





# encoding: UTF-8
#
# 
# 
# rows, columns = $stdin.winsize
# 
# 
# include Curses
# 
# Curses.init_screen
# END { Curses.close_screen }
# 
# Curses.start_color
# Curses.use_default_colors
# Curses.stdscr.keypad(true) # enable arrow keys (required for pageup/down)
# 
# 
# 
# # Determines the colors in the 'attron' below
# Curses.init_pair(1, COLOR_BLUE , COLOR_BLACK)
# Curses.init_pair(2, COLOR_WHITE, -1)
# 
# Curses.bkgd(color_pair(2) | A_BOLD)
# Curses.clear
# Curses.setpos(5,5)
# 
# 
# Curses.attron(color_pair(1)| A_BOLD) {
#   Curses.addstr("Hello! : " + Curses.color_pairs.to_s + " color pairs!")
# }
# 
# # Curses.stdscr.box('│', '─', '┼')
# Curses.setpos(0,0)
# Curses.addstr("┼"  + "─" * (columns - 2) + "┼")
# 
# # ┌────────────────────────────┐
# # │                            │
# # └────────────────────────────┘
# #
# 
# 
# # ─   ━   │   ┃   ┄   ┅   ┆   ┇   ┈   ┉   ┊   ┋   ┌   ┍   ┎   ┏
# # ┐   ┑   ┒   ┓   └   ┕   ┖   ┗   ┘   ┙   ┚   ┛   ├   ┝   ┞   ┟
# 
# # Curses.refresh
# Curses.stdscr.noutrefresh
# Curses.doupdate
# 
# 
# 
# sleep 3
