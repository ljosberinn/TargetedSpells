---@diagnostic disable: undefined-global
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local lookup = {}
for i = 1, #chars do
	lookup[chars:sub(i, i)] = i - 1
end

local function encode(data)
	local pad = #data % 3
	local padded = data .. string.rep("\0", (3 - pad) % 3)
	local out = {}
	for i = 1, #padded, 3 do
		local a, b, c = padded:byte(i, i + 2)
		local n = a * 65536 + b * 256 + c
		out[#out + 1] = chars:sub(math.floor(n / 262144) + 1, math.floor(n / 262144) + 1)
		out[#out + 1] = chars:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
		out[#out + 1] = chars:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
		out[#out + 1] = chars:sub(n % 64 + 1, n % 64 + 1)
	end
	if pad == 1 then
		out[#out - 1] = "="
		out[#out] = "="
	end
	if pad == 2 then
		out[#out] = "="
	end
	return table.concat(out)
end

local function decode(data)
	data = data:gsub("[^" .. chars .. "=]", "")
	local out = {}
	for i = 1, #data, 4 do
		local a = lookup[data:sub(i, i)] or 0
		local b = lookup[data:sub(i + 1, i + 1)] or 0
		local c_val = lookup[data:sub(i + 2, i + 2)]
		local d_val = lookup[data:sub(i + 3, i + 3)]
		local n = a * 262144 + b * 4096
		if c_val then
			n = n + c_val * 64
		end
		if d_val then
			n = n + d_val
		end
		out[#out + 1] = string.char(math.floor(n / 65536))
		if c_val then
			out[#out + 1] = string.char(math.floor(n / 256) % 256)
		end
		if d_val then
			out[#out + 1] = string.char(n % 256)
		end
	end
	return table.concat(out)
end

return { encode = encode, decode = decode }
