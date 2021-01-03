require "kemal"
require "celestine"
require "big/big_int"

WIDTH = 800
HEIGHT = 600

RULE = 30_u8

SCALE = 4
MAX = WIDTH // SCALE

get "/" do
    %(
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
            <title>Genuary 2</title>
        </head>
        <body>
            nothing interesting, just a basic elementary automaton simulator lel<br/>
            
            <a href="/rule/30">rule 30</a><br/>
            <a href="/rule/60">rule 60</a><br/>
            <a href="/rule/110">rule 110</a><br/>

            or, go to /rule/&lt;rule number&gt; to simulate an arbitrary rule
        </body>
        </html>
    )
end

get "/rule/:rule" do |env|
    rule = env.params.url["rule"].to_i32
    if rule > 255 || rule < 0
        env.redirect "/"
    else
        Celestine.draw do |ctx|
            ctx.width = WIDTH
            ctx.height = HEIGHT
            ctx.width_units = ctx.height_units = "px"

            state = 1_u8

            (HEIGHT // SCALE).times do |y|
                bits = state.to_s(2).chars.map(&.to_u8)
                new = [] of UInt8
                lcr = [] of UInt8
                lcr << bits[0]
                bits.size.times do |i|
                    bit = bits[i]
                    
                    l = if i > 0
                            bits[i - 1]
                        else
                            0_u8
                        end
                    r = if i < bits.size - 1
                            bits[i + 1]
                        else
                            0_u8
                        end
                    lcr << (l << 2 | bit << 1 | r)
                end
                lcr << (bits[bits.size - 1] << 2)
                lcr.each do |i|
                    new << ((rule & (1 << i)) == 0 ? 0_u8 : 1_u8)
                end

                new.size.clamp(0, MAX).times do |x|
                    if new[x] != 0
                        ctx.rectangle do |r|
                            r.x = x * SCALE
                            r.y = y * SCALE
                            r.width = r.height = SCALE
                            r.fill = "white"

                            r.animate do |a|
                                a.attribute = "fill"

                                a.values = ["white", "black"] of SIFNumber

                                a.custom_attrs = {
                                    "begin" => "#{y / 4}s"
                                }
                                a.calc_mode = "discrete"
                                a.freeze = true
                                a.duration = 0.4

                                a
                            end

                            r
                        end
                    end
                end

                state = BigInt.new new.join, 2
            end 
        end
    end
end

Kemal.run
