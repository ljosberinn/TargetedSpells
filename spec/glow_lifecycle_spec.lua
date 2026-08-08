---@diagnostic disable: undefined-global, undefined-field

-- The glow stamp: a pooled frame keeps its glow across a release, so ShowGlow has to decide
-- between re-showing what is there, re-sizing it, and returning it to its pool. Getting that
-- decision wrong is a visual-only bug in multi-group configurations, which is exactly what
-- casual testing misses — so the whole decision table is pinned here by call count.

local b = require("spec.bootstrap")
local Private = b.Private
local GlowType = Private.Enum.GlowType
local Element = Private.Enum.Element

-- SizeStar4Glow is the only part of the mixin that reaches for a frame API. Assigned through
-- _G explicitly (as spec/driver_shard_spec.lua does) because busted sandboxes spec files, so a
-- plain global would land in this file's env rather than the one the mixin resolves against.
_G.PixelUtil = {
	SetSize = function(region, width, height)
		region.width = width
		region.height = height
	end,
	SetPoint = function() end,
}

local function StubGlow()
	local glow = { shown = false }

	function glow:Show()
		self.shown = true
	end

	function glow:Hide()
		self.shown = false
	end

	function glow:SetAlphaFromBoolean(value)
		self.alphaBoolean = value
	end

	return glow
end

local function StubStar4()
	local star4 = StubGlow()

	star4.Inner = StubGlow()
	star4.Outer = StubGlow()
	star4.Animation = { playing = false }

	function star4.Animation:Play()
		self.playing = true
	end

	function star4.Animation:Stop()
		self.playing = false
	end

	return star4
end

-- The point of the stamp is how often the library is entered at all, so the stub counts calls
-- and mirrors what the real functions do to the frame: *_Start parks its object on the frame
-- and shows it, *_Stop returns it to a pool and clears the field.
local calls = {}

local function Count(name)
	calls[name] = (calls[name] or 0) + 1
end

local function Starter(field)
	return function(frame)
		Count(field .. "_Start")
		frame[field] = frame[field] or StubGlow()
		frame[field]:Show()
	end
end

local function Stopper(field)
	return function(frame)
		Count(field .. "_Stop")
		frame[field] = nil
	end
end

Private.Glows = {
	PixelGlow_Start = Starter("_PixelGlow"),
	PixelGlow_Stop = Stopper("_PixelGlow"),
	AutoCastGlow_Start = Starter("_AutoCastGlow"),
	AutoCastGlow_Stop = Stopper("_AutoCastGlow"),
	ProcGlow_Start = Starter("_ProcGlow"),
	ProcGlow_Stop = Stopper("_ProcGlow"),
}

loadfile("TargetedSpellsMixin.lua")("TargetedSpells", Private)

-- An icon-shaped frame: the base GetGlowFrame returns `self`, so the stamp lands on the frame.
local function MakeFrame(glowType, width, height)
	local frame = {}

	for name, method in pairs(TargetedSpellsMixin) do
		frame[name] = method
	end

	frame.group = {
		GlowType = glowType,
		GlowImportant = true,
		Elements = {
			[Element.Icon] = { width = width or 48, height = height or 48 },
		},
	}

	frame.GetCoreElement = function()
		return Element.Icon
	end

	return frame
end

describe("glow lifecycle", function()
	before_each(function()
		calls = {}
	end)

	describe("first acquire", function()
		it("builds the glow and stamps type and size", function()
			local frame = MakeFrame(GlowType.PixelGlow, 40, 30)

			frame:ShowGlow(true)

			assert.equals(1, calls._PixelGlow_Start)
			assert.equals(GlowType.PixelGlow, frame.appliedGlowType)
			assert.equals(40, frame.appliedGlowWidth)
			assert.equals(30, frame.appliedGlowHeight)
			assert.is_true(frame._PixelGlow.shown)
			assert.is_true(frame._PixelGlow.alphaBoolean)
		end)

		it("does nothing for an unrecognised glow type", function()
			local frame = MakeFrame(999)

			frame:ShowGlow(true)

			assert.is_nil(frame.appliedGlowType)
			assert.is_nil(calls._PixelGlow_Start)
		end)

		it("does nothing when the frame has no group", function()
			local frame = MakeFrame(GlowType.PixelGlow)
			frame.group = nil

			frame:ShowGlow(true)

			assert.is_nil(frame.appliedGlowType)
		end)
	end)

	describe("HideGlow parks rather than releases", function()
		it("hides the glow but keeps its pooled objects and its stamp", function()
			local frame = MakeFrame(GlowType.PixelGlow)
			frame:ShowGlow(true)

			frame:HideGlow()

			assert.is_not_nil(frame._PixelGlow)
			assert.is_false(frame._PixelGlow.shown)
			assert.is_nil(calls._PixelGlow_Stop)
			assert.equals(GlowType.PixelGlow, frame.appliedGlowType)
		end)

		-- the old implementation called all three unconditionally, on every release
		it("never touches the glow types that are not active", function()
			local frame = MakeFrame(GlowType.PixelGlow)
			frame:ShowGlow(true)

			frame:HideGlow()

			assert.is_nil(calls._AutoCastGlow_Stop)
			assert.is_nil(calls._ProcGlow_Stop)
		end)

		it("does nothing at all on a frame that never glowed", function()
			local frame = MakeFrame(GlowType.PixelGlow)

			frame:HideGlow()

			assert.same({}, calls)
		end)

		it("stops the Star4 animation", function()
			local frame = MakeFrame(GlowType.Star4)
			frame._Star4 = StubStar4()

			frame:ShowGlow(true)
			assert.is_true(frame._Star4.Animation.playing)

			frame:HideGlow()

			assert.is_false(frame._Star4.Animation.playing)
			assert.is_false(frame._Star4.shown)
			assert.is_false(frame._Star4.Inner.shown)
		end)
	end)

	describe("re-acquire into the same group", function()
		it("re-shows the parked glow without rebuilding it", function()
			local frame = MakeFrame(GlowType.PixelGlow)
			frame:ShowGlow(true)
			frame:HideGlow()

			frame:ShowGlow(false)

			assert.equals(1, calls._PixelGlow_Start)
			assert.is_nil(calls._PixelGlow_Stop)
			assert.is_true(frame._PixelGlow.shown)
		end)

		it("still re-applies the per-cast alpha on the cheap path", function()
			local frame = MakeFrame(GlowType.PixelGlow)
			frame:ShowGlow(true)
			frame:HideGlow()

			frame:ShowGlow(false)

			assert.is_false(frame._PixelGlow.alphaBoolean)
		end)

		it("replays the Star4 animation", function()
			local frame = MakeFrame(GlowType.Star4)
			frame._Star4 = StubStar4()

			frame:ShowGlow(true)
			frame:HideGlow()
			frame:ShowGlow(true)

			assert.is_true(frame._Star4.Animation.playing)
			assert.is_true(frame._Star4.Inner.shown)
			assert.is_true(frame._Star4.Outer.shown)
		end)
	end)

	describe("re-acquire into a group that differs", function()
		it("re-runs Start when the core size changed, without releasing", function()
			local frame = MakeFrame(GlowType.PixelGlow, 40, 30)
			frame:ShowGlow(true)
			frame:HideGlow()

			frame.group.Elements[Element.Icon].width = 80
			frame:ShowGlow(true)

			-- *_Start re-sizes in place, so there is nothing to hand back to a pool
			assert.equals(2, calls._PixelGlow_Start)
			assert.is_nil(calls._PixelGlow_Stop)
			assert.equals(80, frame.appliedGlowWidth)
		end)

		it("releases the previous glow when the type changed", function()
			local frame = MakeFrame(GlowType.PixelGlow)
			frame:ShowGlow(true)
			frame:HideGlow()

			frame.group.GlowType = GlowType.ProcGlow
			frame:ShowGlow(true)

			assert.equals(1, calls._PixelGlow_Stop)
			assert.is_nil(frame._PixelGlow)
			assert.equals(1, calls._ProcGlow_Start)
			assert.equals(GlowType.ProcGlow, frame.appliedGlowType)
			assert.is_true(frame._ProcGlow.shown)
		end)

		it("only hides Star4 when switching away from it, since it is not pooled", function()
			local frame = MakeFrame(GlowType.Star4)
			frame._Star4 = StubStar4()
			frame:ShowGlow(true)

			frame.group.GlowType = GlowType.PixelGlow
			frame:ShowGlow(true)

			assert.is_not_nil(frame._Star4)
			assert.is_false(frame._Star4.shown)
			assert.is_false(frame._Star4.Animation.playing)
			assert.equals(1, calls._PixelGlow_Start)
		end)

		it("re-sizes an existing Star4 rather than leaving it at the old size", function()
			local frame = MakeFrame(GlowType.Star4, 40, 40)
			frame._Star4 = StubStar4()

			frame:ShowGlow(true)
			assert.equals(40 * 1.9, frame._Star4.width)

			frame:HideGlow()
			frame.group.Elements[Element.Icon].width = 100
			frame.group.Elements[Element.Icon].height = 100
			frame:ShowGlow(true)

			assert.equals(100 * 1.9, frame._Star4.width)
			assert.equals(100 * 2.2, frame._Star4.Outer.width)
		end)
	end)

	it("stamps the glow frame, not the mixin, when they differ (the bar template)", function()
		local frame = MakeFrame(GlowType.PixelGlow)
		local progressBar = {}

		frame.GetGlowFrame = function()
			return progressBar
		end

		frame:ShowGlow(true)

		assert.equals(GlowType.PixelGlow, progressBar.appliedGlowType)
		assert.is_nil(frame.appliedGlowType)
		assert.is_not_nil(progressBar._PixelGlow)

		frame:HideGlow()

		assert.is_false(progressBar._PixelGlow.shown)
	end)
end)
