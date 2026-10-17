---@diagnostic disable: undefined-global, undefined-field

-- PixelGlow lays its dashes out along the perimeter purely through texture coordinates. A slip there
-- (the pattern jumping at a corner, a lap that does not close) only shows in game, so the layout is
-- pinned here against stubbed regions. Assigned through _G for the same reason as in
-- spec/driver_shard_spec.lua: Glows.lua resolves globals against _G, not this file's sandbox.

local b = require("spec.bootstrap")
local Private = b.Private

local DASH_COUNT = 8
local acquired = 0

local function StubTexture()
	local texture = {}

	function texture:SetTexture()
		return true
	end

	function texture:SetVertexColor() end

	function texture:SetTexCoord(...)
		self.texCoord = { ... }
	end

	return texture
end

local function StubGlowFrame()
	local frame = { Animation = { playing = false } }

	for _, side in ipairs({ "Top", "Right", "Bottom", "Left" }) do
		frame[side] = StubTexture()
	end

	function frame.Animation:Play()
		self.playing = true
	end

	function frame.Animation:Stop()
		self.playing = false
	end

	function frame.Animation:IsPlaying()
		return self.playing
	end

	function frame:SetScript() end
	function frame:SetParent() end
	function frame:SetFrameLevel() end
	function frame:SetAllPoints() end
	function frame:Show() end

	return frame
end

_G.CreateTexturePool = function()
	return {}
end

-- only the PixelGlow pool is ever acquired from in this file
_G.CreateFramePool = function(_, _, _, _, _, initializer)
	return {
		Acquire = function()
			acquired = acquired + 1
			local frame = StubGlowFrame()

			if initializer then
				initializer(frame)
			end

			return frame
		end,
		Release = function() end,
	}
end

loadfile("Glows.lua")("TargetedSpells", Private)

local function Near(expected, actual)
	assert.is_true(math.abs(expected - actual) < 1e-9, string.format("expected %s, got %s", expected, actual))
end

local function StartOn(width, height)
	local target = {
		GetFrameLevel = function()
			return 1
		end,
	}

	Private.Glows.PixelGlow_Start(target, width, height)

	return target
end

-- 4-argument SetTexCoord: left, right, top, bottom
-- 8-argument SetTexCoord: (u, v) of the upper-left, lower-left, upper-right and lower-right corners
describe("PixelGlow dash layout", function()
	for _, size in ipairs({ { 48, 48 }, { 300, 30 }, { 17, 63 } }) do
		local width, height = size[1], size[2]

		it(string.format("continues the pattern across every corner at %dx%d", width, height), function()
			local glow = StartOn(width, height)._PixelGlow
			local top, right, bottom, left = glow.Top.texCoord, glow.Right.texCoord, glow.Bottom.texCoord,
				glow.Left.texCoord

			Near(top[2], right[1])
			Near(right[3], bottom[2])
			Near(bottom[1], left[3])
			-- the lap closes on a whole number of dashes, which the repeating texture treats as 0
			Near(DASH_COUNT, left[1] - top[1])
		end)

		it(string.format("spaces the dashes evenly on every side at %dx%d", width, height), function()
			local glow = StartOn(width, height)._PixelGlow
			local top, right, bottom, left = glow.Top.texCoord, glow.Right.texCoord, glow.Bottom.texCoord,
				glow.Left.texCoord
			local dashesPerUnit = DASH_COUNT / (2 * (width + height))

			Near(dashesPerUnit, (top[2] - top[1]) / width)
			Near(dashesPerUnit, (right[3] - right[1]) / height)
			Near(dashesPerUnit, (bottom[1] - bottom[2]) / width)
			Near(dashesPerUnit, (left[1] - left[3]) / height)
		end)
	end

	it("runs u along the length of the vertical sides", function()
		local glow = StartOn(48, 48)._PixelGlow

		for _, side in ipairs({ "Right", "Left" }) do
			local coords = glow[side].texCoord

			Near(coords[1], coords[5])
			Near(coords[3], coords[7])
			Near(0, coords[2])
			Near(0, coords[4])
			Near(1, coords[6])
			Near(1, coords[8])
		end
	end)

	it("keeps its pooled frame and animation when restarted at a new size", function()
		local before = acquired
		local target = StartOn(48, 48)
		local glow = target._PixelGlow

		Private.Glows.PixelGlow_Start(target, 300, 30)

		assert.equals(before + 1, acquired)
		assert.equals(glow, target._PixelGlow)
		assert.is_true(glow.Animation:IsPlaying())
	end)
end)
