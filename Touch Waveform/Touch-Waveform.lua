-- softcut study 8: copy
--
-- K1 load backing track
-- K2 random copy/paste
-- K3 save clip
-- E1 level

fileselect = require 'fileselect'

m = midi.connect()

file1 = _path.dust.."audio/Softcut Study 8 Loop.wav"
file2 = _path.dust.."audio/hermit-leaves.wav"


saved = "..."
level = 1.0
rec = 1.0
pre = 1.0
length = 1
position = 1
pos = 1
rate = 1
selecting = false
--waveform_loaded = false
dismiss_K2_message = false


function load_file(file, buffer)

    local ch, samples = audio.file_info(file)
    print(buffer)
    length = samples/48000
    softcut.buffer_read_mono(file,0,1,-1,1, buffer)
    reset(buffer)
    waveform_loaded = true
end

function update_positions(i,pos)
  position = (pos - 1) / length
  if selecting == false then redraw() end
end

function reset(i)
  print(i)
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(i,1.0)
    softcut.loop(i,1)
    softcut.loop_start(i,1)
    softcut.loop_end(i,1+length)
    softcut.position(i,1)
    softcut.rate(i,1.0)
    softcut.play(i,1)
    softcut.fade_time(1,0.5)
  --update_content(1,1,length,128)
end


-- WAVEFORMS
local interval = 0
waveform_samples = {}
scale = 30

function on_render(ch, start, i, s)
  waveform_samples = s
  interval = i
  redraw()
end

function update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end
--/ WAVEFORMS

function init()
  softcut.buffer_clear()
  
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)

  softcut.phase_quant(1,0.01)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()
  softcut.event_render(on_render)

  reset(1)
  reset(2)
end

function key(n,z)
  if n==1 and z==1 then
    selecting = true
    print (_path.dust)
    fileselect.enter(_path.dust,load_file)
  elseif n==2 and z==1 then
    
    softcut.buffer_clear()
    load_file(file1, 1)
    
    
    load_file(file2, 2)
    
    
  elseif n==3 and z==1 then
    --saved = "ss7-"..string.format("%04.0f",10000*math.random())..".wav"
    --softcut.buffer_write_mono(_path.dust.."/audio/"..saved,1,length,1)
  end
end

function enc(n,d)
  if n==1 then
    level = util.clamp(level+d/100,0,2)
    softcut.level(1,level)
  elseif n==2 then
    -- This encoder controls the position of Softcut channel 1.
    -- It seems to work well with files greater than 2 minutes, but otherwise isn't stable.
    pos = util.clamp(position + (pos + d), 0, 48000)
    softcut.position(1,pos)
    print(pos)
  elseif n==3 then
    rate = util.clamp(rate + (d * 0.1), -100, 10)
    softcut.rate(1, rate)
  end
  redraw()
end

-- CC Messages
m.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    --softcut.rec_level(1, d.note * 0.03)
  end
  if d.type == "cc" then
    print("cc " .. d.cc .. " = " .. d.val)
    if (d.cc == 0) then
      pos = util.clamp((d.val / 128) * length, 0, 48000)
      softcut.position(1, pos)
      print(pos)
    elseif (d.cc == 1) then
      pos2 = util.clamp((d.val / 128) * length, 0, 48000)
      softcut.position(2, pos2)
    end
  end
  redraw()
end

function redraw()
  screen.clear()
  if not waveform_loaded then
    screen.level(15)
    screen.move(62,50)
    screen.text_center("hold K1 to load sample")
  else
    screen.level(15)
    screen.move(62,10)
    if not dismiss_K2_message then
      screen.text_center("K2: random copy/paste")
    else
      screen.text_center("K3: save new clip")
    end
    screen.level(4)
    local x_pos = 0
    for i,s in ipairs(waveform_samples) do
      local height = util.round(math.abs(s) * (scale*level))
      screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
    screen.level(15)
    screen.move(util.linlin(0,1,10,120,position),18)
    screen.line_rel(0, 35)
    screen.stroke()
  end
  
  screen.update()
end