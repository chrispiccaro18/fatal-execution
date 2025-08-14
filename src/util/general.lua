local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end
local function lerp(a,b,t) return a + (b - a) * t end
local function easeOutCubic(t) t = clamp(t,0,1); return 1 - (1 - t)^3 end
local function rad(deg) return deg * math.pi / 180 end
local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

return { clamp = clamp, lerp = lerp, easeOutCubic = easeOutCubic, rad = rad, dump = dump }
