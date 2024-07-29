# title:   A Swordfish Tale
# author:  Andrew Owen <yumaikas94@gmail.com>
# desc:    A mother swordfish protects her young from The Naturalist
# site:    website link
# license: MIT License
# version: 0.1
# script:  ruby
# saveid: yumaikas/swordfish-tale

include Math

def sign(n) n == 0 ? 0 : n > 0 ? 1 : -1 end
def nop() end
def lerp(a,b,t) (1-t)*a+t*b end
def max(a,b) a > b ? a : b end
def min(a,b) a < b ? a : b end
def mod?(a,*b) b.any? { |c| a%c==0 } end
def abs(a) a < 0 ? -a : a end
def mag(x,y)
	x=x.to_f
	y=y.to_f
 sqrt(x*x + y*y)
end
def norm(x,y) 
	m = mag(x,y)
	[x.to_f/m, y.to_f/m]
end
def roll(range)
	range.min + rand((range.max+1) - range.min)
end

def gcd(a, b)
  if a == 0 or b == 0
   1
  elsif a % b == 0
   b
  else
   gcd(b, a % b)
  end
end

class D
	class << self
		def on?; @on end 
		def enable; @on=true end
		def disable; @on=false end
		@on = false
		def bg
			if @on
				yield
			end		
		end
	end
end

module Coord
	def put(x,y) @x=x;@y=y end
	def move_to(o) put(o.x,o.y) end
	def moved_by(x,y) [@x+x,@y+y] end
	def at() [@x,@y] end
	def clamp(xmin,xmax,ymin,ymax)
		@x=@x.clamp(xmin,xmax)
		@y=@y.clamp(ymin,ymax)
	end
	def move_by(o) @x+=o.y; @y+=o.y end
	def move_dxy(x,y) @x+=x; @y+=y end
	def dist(o) sqrt((@x - o.x)**2 + (@y - o.y)**2) end
	def towards(o) [o.x-@x,o.y-@y] end
	def aim4(o)
		dx,dy=towards(o)
		if dx.abs > dy.abs
			[sign(dx),0]
		else
			[0, sign(dy)]
		end
	end
	def aim8(o)
		dx,dy=towards(o)
		[sign(dx),sign(dy)]
	end
end

module HP
	def init_hp(amt, *types)
		@HP = amt
		@vuln_types = types
	end

	def hurt!(amt, type)
		if @vuln_types.member?(type)
			@HP -= amt
		end
	end
end

module Collide
	def overlaps?(b)
	 a=self
		if patt a,:aabb, b,:radial
			coll_aabb_radial(a,b)
		elsif patt a,:radial, b,:aabb
			coll_aabb_radial(b,a)
		elsif patt a,:aabb, b,:aabb
			a.x<b.x+b.y and a.x+a.y>b.x and a.y<b.x+b.h and a.y+a.h>b.y
		elsif patt a,:radial, b,:radial
			a.dist(b) <= a.r + b.r
		else
			false
		end
	end
	def type(ct) @coll_type=ct end
	
	def get_cells(xc,yc,&blk)
		if coll_type == :aabb
			tl = [x/xc,y/yc]
			br = (tl[0]+w),(tl[1]+h)
			cross((tl[0]..br[0]),(tl[1]..br[1]), &blk)
		elsif coll_type == :radial
			tl = [(x-r)/xc,(y-r)/yc]
			br = [(x+r)/xc,(y+r)/yc]
			cross((tl[0]..br[0]),(tl[1]..br[1]), &blk)
		end
	end
	
	private
	def patt(a,ka,b,kb) 
		a.coll_type == ka and b.coll_type == kb 
	end
	
	def coll_aabb_radial(c,r)
		tX=c.x
		tY=c.y
		if c.x<r.x
			tX=r.x
		elsif c.x<r.x+r.w
			tX=rx+rw
		end
		if c.y<r.y
			tY=r.y
		elsif c.y<r.y+r.h
			tY=r.y+r.h
		end
		dX=c.x-tX
		dY=c.y-tY
		d=sqrt((dX*dX)+(dY*dY))
		
		d<=c.r
	end
end

class Radial
	include Collide, Coord
	attr_accessor :x,:y,:r
	def initialize(x,y,r)
		@x=x
		@y=y
		@r=r
		type :radial
	end
	def draw(c) K.circ @x,@y,@r,c end
end

class AABB
 include Collide, Coord
 attr_reader *%i(x y w h)
	def initialize(x,y,w,h) 
		@x=x;@y=y;@w=w;@h=h
		type :aabb
	end
	private 
	def dist; end
end

C_CONF = [[:U,0],[:D,1],[:L,2],[:R,3],[:A,4],[:B,5],[:X,6],[:Y, 7]]
class Controller 
 attr_reader :player
	
	def initialize(player) 
		@player = player - 1 
		@chks = {}
		C_CONF.each do |c|
			@chks[c[0]] = "#{c[0]}?".intern
			@chks["#{c[0]}p"] = "#{c[0]}p?".intern
		end
	end
	
	def pressed?(*args)
		args.all? do |c|
			send @chks[c] if @chks[c]
		end
	end
	
	C_CONF.each do |c|	
		define_method("#{c[0]}?") do
			btn c[1]+8*@player
		end
		define_method("#{c[0]}p?") do
			btnp c[1]+8*@player
		end
	end	
end

C1=Controller.new(1)

T80=self
class Camera
 include Coord
	def initialize(x,y)
		@x_off=120
		@y_off=68
		@x=x
		@y=y
	end
	def t(x,y, *args) [x-@x+@x_off, y-@y+@y_off, *args] end
	def spr(id, *args) T80.spr id,*t(*args) end
	def map(x,y,w,h,sx,sy,*args)
		T80.map x,y,w,y,*t(sx,sy,*args)
	end
	def circ(*args) T80.circb *t(*args) end
	def line(x,y,x1,y1,c) T80.line *t(x,y,*t(x1,y1,c)) end
	def pix(*args) T80.pix *t(*args) end
	def clip(*args) T80.clip(*t(*args)) end
	def r(s, *args) T80.print s,*t(*args) end
	def s(text,x,y,c=15,f=false,s=1)
	 r(text,x,y,c,f,s,true)
	end
	def rect(x,y,w,h,c)
		T80.rectb *t(x,y,w,h,c)
	end
	def bg_map()
		# Adapted from https://tic80.com/play?cart=161
		# but, kinda inverted, since my camera seems to be working differently	
		ccx=@x/8
		ccy=@y/8
		T80.map(ccx-15,ccy-8,32,18,(8-(@x%8))-8,(8-(@y%8))-8,00,1)
	end
end

K=Camera.new(0,0)

class Animation
	def initialize(frames)
		@frames = frames
		@t=0
		@idx=0
	end
	def tic!
		@t+=1
		if @frames[@idx+1] < @t
			@idx+=2
		end
		if @idx>=@frames.size
			@idx=0
			@t=0
		end
	end
	def get; @frames[@idx] end
end


class Shot
	include Coord
	def initialize(x,y,dx,dy)
		put x,y
		@t=0
		@dx=dx;@dy=dy
	end
	
	def tic!
		@t+=1
		move_dxy @dx,@dy
		move_dxy @dx,@dy
		move_dxy @dx,@dy
	end
	
	def live?; @t<120 end
	def kill!; @t=121 end
	def draw
		K.line(@x,@y,@x-(@dx*6),@y-(@dy*6),4)
	end
end

class Bomb
	include Coord
	def initialize(x,y,dx)
		put x,y
		@dx=dx
		@t=0
	end
	def tic!
		@t+=1
		cyc = @t%6
		case cyc
			when 0
				move_dxy @dx,-1
			when 1
				move_dxy 0,-1
			when 2
				move_dxy @dx,-1
			when 3
				move_dxy 0,-1
			when 4
				move_dxy @dx,-1
			when 5
				move_dxy 0,-1
		end
	end
	def live?; @t<120 end
	def draw
		K.circ(@x-1,@y-3,min(6, max(2,@t/15)),9)
	end
end

class Player
	include Coord
	attr_reader :spawned,:x,:y
	def initialize(x,y,b)
		put x,y
		@b=b
		@t=0
		@gt=0
		@bt=0
		@flip=false
		@spawned=[]
	end
	
	def draw
		flip = @flip ? 0 : 1
		K.spr 256,*at,0,1,flip,0,2,1
	end
	def tic!
	 @t+=1
		@gt+=1
		@bt+=1
		if mod?(@t,1)
			if @b.R?; @x+=1;@flip=true end
			if @b.L?; @x-=1;@flip=false end
		end
		if mod?(@t,1)
			if @b.U?; @y-=1 end
			if @b.D?; @y+=1 end
		end
		
		if @b.Yp? and @gt > 6
			@gt=0
			dx=@flip ? 1:-1 
			@spawned << [:shots, Shot.new(@x+8,@y+5,dx,0)]
		end
		if @b.Xp? and @bt > 60
			@bt = 0
			dx=@flip ? 1:-1
			@spawned << [:shots, Bomb.new(@x+8,@y+7,dx)]
		end
		# TODO: Clamp player position
	end
end

class XY
	include Coord
	attr_accessor :x,:y
	def self.midcell(xc,yc) new((xc * 8) + 4, (yc * 8) + 4) end
	def initialize(x,y) put x,y end
end

class LineFollow
 def initialize(x0,y0,x1,y1)
  @x0=x0
  @y0=y0
  @x1=x1
  @y1=y1
  @step = norm(@x1-@x0, @y1-@y0)
  @pos = XY.new(@x0.to_f,@y0.to_f)
 end

 def step()
 	@pos.move_dxy(*@step)
  x,y = @pos.at
  [x.to_i, y.to_i]
 end
end

def pick_swim_loc
	[roll(0..(8*239)), roll((8*69)..(8*101))]
end

class Claw
	include Coord
	attr_accessor :x,:y,:children
	def initialize(x,y,ty,cy,on_drop,children)
		put x,y
		@ty=ty
		@iy = y
		@t=0
		@state=:lowering
		@on_drop = on_drop
		@children = @children
	end
	
	def live?
		@state == :raising and @y < @iy
	end
	
	def tic!
		@t+=1
		if @state == :raising and mod?(@t,4)
			@y -= 1
		end
		if @state == :lowering and mod?(@t,4)
			@y += 1
		end
		
		if @y >= @ty
			@y -= 1
			@state=:raising
			@on_drop.call()
		end
		@children.each(&:tic!)
	end
	
	def draw
		((@y/8)..(@cy/8)).each { |cy| K.spr(352, @x-4, cy*8) }
		K.spr(368, @x-4,@y-4,0)
		@children.each(&:draw)
	end
end

class Bubble
	include Coord
	def initialize(x,y)
		put x,y
		@t=0
	end
	
	def tic!
		move_dxy 0,-1
		@t+=1
	end
	def live?; @t<60 end
	def draw
		K.circ(*at, max(1, @t.div(20)), 11)
	end
end

class PinkFish
	include Coord
	attr_accessor :x,:y
	def initialize(x,y,n)
		put x,y
		@fish = (0..roll(2..n)).map { XY.new(roll(-4..4), roll((-4)..4))}
		@target = XY.new(*pick_swim_loc())
		@mover = LineFollow.new(*at, *@target.at)
		@mt=0
		@t=0
		@bubbles = []
	end
	def tic!
		@t+=1
		@fish.each do |f|
			if roll(0..20) > 19
				f.move_dxy roll(-1..1),roll(-1..1)
				f.clamp(-8,8,-8,8)
			end
		end
		if dist(@target) < 2
			retarget
		elsif mod?(@t,4)
			put(*@mover.step)
		end
		if roll(0..100) > 99
			@bubbles << Bubble.new(*at)
		end
		@bubbles.each(&:tic!)
		@bubbles.select!(&:live?)
	end
	def draw
		@fish.each { |f| K.line(@x+f.x,@y+f.y,@x+f.x+1,@y+f.y,6) }
		@bubbles.each(&:draw)
		D.bg { K.line(*at, *@target.at, 12) } 
	end

    def live?; true end
	
	private
	def retarget
		@target.put(*pick_swim_loc())
		@mover = LineFollow.new(*at, *@target.at)
	end
end

KidMasc = 272
KidFemme = 273

class KidFish
	include Coord
	def initialize(x,y, safe_spots,spr_id)
		put x,y
		@presentation = spr_id
		@state = :wander
		@safe_spots = safe_spots
		retarget(XY.new(*pick_swim_loc))
		@t=0
		@flip=false
	end
	
	def mod_speed; @state == :hide ? 4 : 8 end

    # TODO: Add a health pool
    def live?; true end
	
	def tic!
		@t+=1
		if (@state == :hide) and dist(@target) < 5
			return
		elsif (@state == :wander) and dist(@target) < 5
			retarget(XY.new(*pick_swim_loc))
		elsif mod?(@t, mod_speed)
			nx,ny = @mover.step
			if nx - @x < 0 and @flip
				@flip = false
			elsif nx - @x > 0 and not @flip
				@flip = true
			end
			put *@mover.step
		end
	end
	
	def draw
		flip = @flip ? 0 : 1
		K.spr(@presentation, *at,0,1,flip)
	end
	
	def wave_start
		@state = :hide
		retarget(@safe_spots.min_by { |s| dist(s) })
	end
	
	def wave_end
		@state = :wander
		retarget(XY.new(*pick_swim_loc))
	end
	
	private 
	def retarget(to)
		@target = to
		@mover = LineFollow.new(*at, *@target.at)
	end
end

P1 = Player.new(0,0,C1)

Shots=[]
Idles=[]
SafeSpots=[
	XY.midcell(141, 100),
	XY.midcell(84, 100),
	XY.midcell(153,100),
	XY.midcell(198,100),
]

def newKid(id)
	KidFish.new(*SafeSpots.sample.at, SafeSpots, id)
end

Kids=[KidFemme,KidFemme,KidFemme,KidFemme,KidMasc,KidMasc,KidMasc,KidMasc].map { |id|
	newKid(id)
}

class Crawler
	include Coord, HP

	def initialize(x,y)
		put x,y
		init_hp 2, :bullet
		@walk_anim = Animation.new([370, 3, 371, 6])
		@target = nil
	end

	def go_to(target); @target = target end

	def live?; @HP > 0 end
	def retarget?; dist(@target) < 4 end

	def tic!
		unless dist(@target) < 4
			@walk_anim.tic!
			@ox, @oy = at
			move_dxy(aim4(*@target.at))
			@flip = @ox < @x
			@flip = @ox > @x
		end
	end

	def draw
		flip = @flip ? 0 : 1
		K.spr @walk_anim.get, *at, 0, 1, flip
	end
end

class Timer
	def initialize(t, &fn)
		@t = t
		@fn = fn
	end
	def live?; @t <= 0 end
	def tic!
		@t -= 1
		if @t <= 0
			@fn.call
		end
	end
end

class CrawlerWave
	class << self
		def start(crawlers, children, top_y) 
          crawlers.each do |cr|
              10.downto(0).each do |i|
					Idles << Timer.new(6 + (10 - i) * 6) do
                      Idles << Bubble.new(cr.x, cr.y - (i*10))
					end
				end
          end
          new(crawlers, children)
		end
	end

	def initialize(crawlers, children)
		@crawlers = crawlers
		@children = children
	end

	def live?; not @crawlers.emtpy? end
	def tic!
		@crawlers.each(&:tic!)
		@crawlers.filter!(&:live?)
		@crawlers.filter(&:retarget?).each do |cr|
			close_child = @children.min_by{|ch| ch.dist(cr)}
			target = XY.new(close_child.at[0], cr.at[1])
			cr.go_to(target)
		end
	end

	def draw
		@crawlers.each(&:draw)
	end
end

Level2 = Class.new do
end

Level1 = Class.new do

  def initialize
    @wave1 = CrawlerWave.start([
      Crawler.new(40, 808),
      Crawler.new(400, 808),
    ], Kids, 40)
  end

  def tic!;
    @wave1.tic!

    unless @wave1.live?
      @next = Level2.new()
    end

  end

  def next; @next end

end

def TIC
	cls 0
	if keyp(42) # Semicolon
		if D.on?
			D.disable
		else
			D.enable
		end
	end
	if keyp(15) # O
		Kids.each(&:wave_start)
	end
	if keyp(16) # P
		Kids.each(&:wave_end)
	end
	P1.tic!
	P1.spawned.each do |s|
      dest, obj = s
      if dest == :shots
		Shots << obj
      end
	end
	P1.spawned.clear

    # Tick various things
	Kids.each(&:tic!)
	Shots.each(&:tic!)
	Idles.each(&:tic!)

    # Draw
	K.put(*P1.at)
	K.bg_map
	Idles.each(&:draw)
	Kids.each(&:draw)
	P1.draw
	Shots.each(&:draw)

    # Debug Draw
    print "@ #{P1.x}, #{P1.y}"
    

    # Cleanup
	Shots.filter!(&:live?)
    Idles.filter!(&:live?)
    Kids.filter!(&:live?)
end

def BOOT
	srand(tstamp())
	P1.put(101*8,98*8)
	
	(0..240).each do |x|
		(0..134).each do |y|
			if [11,12].include?(mget(x,y))
				mset(x,y,0)
				Idles << PinkFish.new(x*8,y*8,5)
			end
		end
	end	
end
# <TILES>
# 004:0000000000000000000aa000200aa00220a99a0220a99a0220a99a0228888882
# 007:0000000000000000000000000000005000000505000050000005000000005000
# 008:0000000000000000000000000000000000000000500000000500000050000000
# 011:0000000000000066000660000000000000000000066000000000066000000000
# 012:0000000000000000000000000660000000000000000000660000000000006600
# 016:0000000000022222022211112111111111111111111111111111111111111111
# 017:0000000022000000112222001111122211111111111111111111111111111111
# 018:0000000000000000000000000002222222221121111111111111111111111111
# 019:0000000000000000000000000000000020000000120000001120000011200000
# 023:0000000500022225022211152111111111111111111111111111111111111111
# 024:0000000022000000112222001111122211111111111111111111111111111111
# 025:000000000002222202221111211111111111b1111b1111111111111111111111
# 026:000000002200000011222200b11112221111111111111b111b11111111111111
# 027:0000000000022222022211112111111111111111111111111111111111111111
# 028:0000000022000000112222001111122211111111111111111111111111111111
# 032:1111111111111111111111111111111111111111111111111111111111111111
# 033:2222222211111111111111111111111111111111111111111111111111111111
# 035:0000000000000000000000000000000000000002000000210000021100000211
# 048:0000000000000000000000000000000000000002000000210000021100000211
# 049:0000000000000000000000002222200012112222111111111111111111111111
# 050:0000000000000022002222112221111111111111111111111111111111111111
# 051:0000000022222000111122201111111211111111111111111111111111111111
# 064:aaaaaaaa00000000000000000000000000000000000000000000000000000000
# </TILES>

# <SPRITES>
# 000:0000000000000000000000000000a0000a00a97900aaaaaa0a0aaacc00000000
# 001:000000000000000000000000000000007b000000aaaaaa00ca60000000000000
# 002:0000650600065555006555550655555506555555006555550006555500006506
# 003:5000000055555500555bb55055baab555bbaab55555bb5505555550050000000
# 016:000000000000000000a0990009aaba0000ca6000000000000000000000000000
# 017:00000000000000000070000007aaba0000ca6000000000000000000000000000
# 096:000e000000e0e000000e000000e0e000000e000000e0e000000e000000e0e000
# 097:000e000000e0e000000e000000e0e000000e000000e0e000000e000000e0e000
# 112:0032230003202230032002300320023003200230003032300000330000030000
# 113:000e000000e0e000eeeeeee0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0eeeeeee0
# 114:0000000000eee0000eeeee00003330000033b000003330000222220020202020
# 115:00eee0000eeeee00003330000033b00000333000022222000202020002020200
# 116:000000000000ee000000ee00300eeee0032222223002bb200000000000000000
# 144:00000000002000002033333002333b3320333330002000000000000000000000
# 145:0000000000200200020330200034430000344300020330200020020000000000
# 146:0000000000000002000000020000000200002223030233330032333e0302333e
# 147:000000002200000033000000300000003222200033332200e3332bb0e3332bb0
# 162:000223ee03023333003233330300222200000000000000000000000000000000
# 163:ee322bb033332bb0333322002222200000000000000000000000000000000000
# 238:000000ee000000ee000000ee000000ee00000eee000000660000006600000222
# 239:ee000000ee000000ee000000ee000000eee00000b60000006600000022200000
# 254:00000333000030330000303300000333000000330000008800000080000000e0
# 255:33300b003303020033003200330002003300020088000200080002000e000200
# </SPRITES>

# <MAP>
# 069:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404
# 075:0000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 078:000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 079:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000c0000000000000000000000000
# 080:00c0000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 081:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000c00000
# 082:000000000000000000000000000000000000000000000000000000000000000000000000b000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000
# 083:00c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 084:00000000000000000000000000000000000000c000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000c000000000000000000000
# 085:0000000000000000000000000000000000c0000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000
# 086:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 087:00000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 088:0000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 089:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 090:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000c00000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c00000000000000000000000000000c00000000000
# 091:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0
# 092:000000000000000000c0000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 094:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 095:00000000000000000000000000000000000000000000000000c00000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000
# 097:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000
# 098:00000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# 100:000000000000b0c000000000000000000000000000000000000000000000000000000000b0c000000000000000000000000000b0c00000000000000000000000000000000000000000000000000000000000000070800000000032011212123331000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070800000000090a00000000070800000000000000090a00000000000000090a00000000000000000000000000090a000000000b0c000000000708000000000000000000000000000b0c000000000000000000000000000000000000000b0c000000000
# 101:011121011121b1c121011121011121011121011121011121011121011121011121011121b1c121011121011121011121011121b1c12101112101112101112101112101114001114001112101114001114001112171813100003212020202020212112101112101112101112101112101112101110111210111212101112101112101112101112101112101112171812101112191a12101112171812101112101112191a12101112101112191a12101112101112101112101112191a121011121b1c12101112171812101112101112191a121011121b1c121011121011121011121011121011121011121b1c121011121
# 102:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020212121212020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 103:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 104:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 105:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 106:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 107:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 108:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 109:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 110:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 111:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 112:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 113:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 114:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 115:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 116:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 117:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# 118:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
# </MAP>

# <WAVES>
# 000:00000000ffffffff00000000ffffffff
# 001:0123456789abcdeffedcba9876543210
# 002:0123456789abcdef0123456789abcdef
# </WAVES>

# <SFX>
# 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
# </SFX>

# <TRACKS>
# 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# </TRACKS>

# <PALETTE>
# 000:1a1c555d275db13e53ef7d57ffcd75a7f070da6995ba14a129366f3b5dc941a6f673eff7f4f4f494b0c2566c86ee0040
# </PALETTE>

