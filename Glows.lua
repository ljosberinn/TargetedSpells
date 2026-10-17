-- MIT License

-- Copyright (c) 2022 Benjamin Staneck

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- this file is a modified version of LibCustomGlow due to the methods below originally calling frame:GetSize().
-- in my use case in this addon, these values are situationally secret and thus you cannot perform any logic on them.
-- instead, methods have been modified to accept width/height as arguments to circumvent this.
-- there's further adjustments such as adding types, lazy initialization of frame pools, pruning stuff I don't need etc.
-- PixelGlow no longer derives from it, see Templates/TargetedSpellsPixelGlowTemplate.xml.

---@diagnostic disable: undefined-field, inject-field

---@type string, TargetedSpells
local _, Private = ...

---@diagnostic disable-next-line: missing-fields
Private.Glows = {}

local textureList = {
	shine = [[Interface\Artifacts\Artifacts]],
}
local shineCoords = { 0.8115234375, 0.9169921875, 0.8798828125, 0.9853515625 }
local GlowParent = UIParent

local GlowTexPool = CreateTexturePool(
	GlowParent,
	"ARTWORK",
	7,
	nil,
	---@param tex Texture
	function(_, tex)
		tex:Hide()
		tex:ClearAllPoints()
	end
)

---@type FramePool<GlowFrame>
local GlowFramePool = CreateFramePool(
	"Frame",
	GlowParent,
	nil,
	---@param frame GlowFrame
	function(_, frame)
		frame:SetScript("OnUpdate", nil)

		local parent = frame:GetParent()
		if parent and parent[frame.name] then
			parent[frame.name] = nil
		end

		if frame.textures then
			for _, texture in pairs(frame.textures) do
				GlowTexPool:Release(texture)
			end
		end

		frame.textures = {}
		frame.info = {}
		frame.name = nil
		frame.timer = nil
		frame.throttle = nil
		frame:Hide()
		frame:ClearAllPoints()
	end
)

---@param frame Frame
---@param color number[]|ColorMixin
---@param name string
---@param count number
---@param texture string
---@param texCoord number[]
---@param desaturated boolean?
---@return GlowFrame
local function AddFrameAndTex(frame, color, name, count, texture, texCoord, desaturated)
	if frame[name] == nil then
		frame[name] = GlowFramePool:Acquire()
		frame[name]:SetParent(frame)
		frame[name].name = name
	end

	---@type GlowFrame
	local GlowFrame = frame[name]
	GlowFrame:SetFrameLevel(frame:GetFrameLevel() + 8)
	GlowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0.05, 0.05)
	GlowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0.05)
	GlowFrame:Show()

	if not GlowFrame.textures then
		GlowFrame.textures = {}
	end

	for Idx = 1, count do
		if not GlowFrame.textures[Idx] then
			GlowFrame.textures[Idx] = GlowTexPool:Acquire()
			GlowFrame.textures[Idx]:SetTexture(texture)
			GlowFrame.textures[Idx]:SetTexCoord(texCoord[1], texCoord[2], texCoord[3], texCoord[4])
			GlowFrame.textures[Idx]:SetDesaturated(desaturated)
			GlowFrame.textures[Idx]:SetParent(GlowFrame)
			GlowFrame.textures[Idx]:SetDrawLayer("ARTWORK", 7)
		end

		if type(color) == "table" and color.GetRGBA then
			GlowFrame.textures[Idx]:SetVertexColor(color:GetRGBA())
		else
			GlowFrame.textures[Idx]:SetVertexColor(color[1], color[2], color[3], color[4])
		end

		GlowFrame.textures[Idx]:Show()
	end

	while #GlowFrame.textures > count do
		GlowTexPool:Release(GlowFrame.textures[#GlowFrame.textures])
		table.remove(GlowFrame.textures)
	end

	return GlowFrame
end

local GLOW_UPDATE_INTERVAL = 1 / 60

do
	local color = { 0.95, 0.95, 0.32, 1 }
	local count = 8
	local sides = { "Top", "Right", "Bottom", "Left" }
	local texture = [[Interface\AddOns\TargetedSpells\Media\PixelGlowDash.tga]]

	---@param self PixelGlowFrame
	local function PlayAnimation(self)
		self.Animation:Play()
	end

	---@param self PixelGlowFrame
	local function StopAnimation(self)
		self.Animation:Stop()
	end

	---@type FramePool<PixelGlowFrame>
	local PixelGlowPool = CreateFramePool(
		"Frame",
		GlowParent,
		"TargetedSpellsPixelGlowTemplate",
		---@param frame PixelGlowFrame
		function(_, frame)
			frame:Hide()
			frame:ClearAllPoints()

			local parent = frame:GetParent()
			if parent and parent._PixelGlow then
				parent._PixelGlow = nil
			end
		end,
		nil,
		---@param frame PixelGlowFrame
		function(frame)
			for _, side in ipairs(sides) do
				frame[side]:SetTexture(texture, "REPEAT", "CLAMP", "NEAREST")
				frame[side]:SetVertexColor(color[1], color[2], color[3], color[4])
			end

			frame:SetScript("OnShow", PlayAnimation)
			frame:SetScript("OnHide", StopAnimation)
		end
	)

	function Private.Glows.PixelGlow_Start(frame, width, height)
		if frame._PixelGlow == nil then
			frame._PixelGlow = PixelGlowPool:Acquire()
		end

		local glowFrame = frame._PixelGlow
		glowFrame:SetParent(frame)
		glowFrame:SetFrameLevel(frame:GetFrameLevel() + 8)
		glowFrame:SetAllPoints(frame)

		-- u runs clockwise along the perimeter from the top-left corner in dash spacings, so each side
		-- continues the pattern where the previous one ends and dashes flow around the corners
		local spacing = 2 * (width + height) / count
		local topRight = width / spacing
		local bottomRight = (width + height) / spacing
		local bottomLeft = (2 * width + height) / spacing

		glowFrame.Animation:Stop()
		glowFrame.Top:SetTexCoord(0, topRight, 0, 1)
		glowFrame.Right:SetTexCoord(topRight, 0, bottomRight, 0, topRight, 1, bottomRight, 1)
		glowFrame.Bottom:SetTexCoord(bottomLeft, bottomRight, 0, 1)
		glowFrame.Left:SetTexCoord(count, 0, bottomLeft, 0, count, 1, bottomLeft, 1)
		glowFrame:Show()

		if not glowFrame.Animation:IsPlaying() then
			glowFrame.Animation:Play()
		end
	end

	function Private.Glows.PixelGlow_Stop(frame)
		if frame._PixelGlow then
			PixelGlowPool:Release(frame._PixelGlow)
		end
	end
end

do
	local color = { 0.95, 0.95, 0.32, 1 }
	local count = 4
	local sizes = { 7, 6, 5, 4 }

	---@param self Frame
	---@param elapsed number
	local function AutoCastGlowOnUpdate(self, elapsed)
		self.throttle = (self.throttle or 0) + elapsed

		if self.throttle < GLOW_UPDATE_INTERVAL then
			return
		end

		local step = self.throttle
		self.throttle = 0

		local width = self.info.width
		local height = self.info.height

		if self.info.needsUpdate then
			self.info.needsUpdate = nil

			if width * height == 0 then
				return
			end

			self.info.width = width
			self.info.height = height
			self.info.perimeter = 2 * (width + height)
			self.info.bottomlim = height * 2 + width
			self.info.rightlim = height + width
			self.info.space = self.info.perimeter / self.info.N
		end

		local TexIndex = 0
		for ring = 1, 4 do
			self.timer[ring] = self.timer[ring] + step / (self.info.period * ring)

			if self.timer[ring] > 1 or self.timer[ring] < -1 then
				self.timer[ring] = self.timer[ring] % 1
			end

			for ParticleIdx = 1, self.info.N do
				TexIndex = TexIndex + 1
				local position = (self.info.space * ParticleIdx + self.info.perimeter * self.timer[ring])
					% self.info.perimeter
				if position > self.info.bottomlim then
					self.textures[TexIndex]:SetPoint("CENTER", self, "BOTTOMRIGHT", -position + self.info.bottomlim, 0)
				elseif position > self.info.rightlim then
					self.textures[TexIndex]:SetPoint("CENTER", self, "TOPRIGHT", 0, -position + self.info.rightlim)
				elseif position > self.info.height then
					self.textures[TexIndex]:SetPoint("CENTER", self, "TOPLEFT", position - self.info.height, 0)
				else
					self.textures[TexIndex]:SetPoint("CENTER", self, "BOTTOMLEFT", 0, position)
				end
			end
		end
	end

	function Private.Glows.AutoCastGlow_Start(frame, width, height)
		local glowFrame = AddFrameAndTex(frame, color, "_AutoCastGlow", count * 4, textureList.shine, shineCoords, true)

		for index, size in pairs(sizes) do
			for ParticleIdx = 1, count do
				glowFrame.textures[ParticleIdx + count * (index - 1)]:SetSize(size, size)
			end
		end

		glowFrame.timer = glowFrame.timer or { 0, 0, 0, 0 }
		glowFrame.throttle = 0
		glowFrame.info = glowFrame.info or {}
		glowFrame.info.N = count
		glowFrame.info.period = 8
		if glowFrame.info.width ~= width or glowFrame.info.height ~= height then
			glowFrame.info.width = width
			glowFrame.info.height = height
			glowFrame.info.needsUpdate = true
		end
		glowFrame.info.perimeter = 2 * (width + height)
		glowFrame.info.bottomlim = height * 2 + width
		glowFrame.info.rightlim = height + width
		glowFrame.info.space = glowFrame.info.perimeter / count

		AutoCastGlowOnUpdate(glowFrame, GLOW_UPDATE_INTERVAL)
		glowFrame:SetScript("OnUpdate", AutoCastGlowOnUpdate)
	end
end

function Private.Glows.AutoCastGlow_Stop(frame)
	if frame._AutoCastGlow then
		GlowFramePool:Release(frame._AutoCastGlow)
	end
end

local ProcGlowPool = CreateFramePool(
	"Frame",
	GlowParent,
	nil,
	function(framePool, frame)
		frame:Hide()
		frame:ClearAllPoints()

		frame:SetScript("OnShow", nil)
		frame:SetScript("OnHide", nil)
		frame.ProcStartAnim:SetScript("OnFinished", nil)
		frame.ProcStartAnim:Stop()
		frame.ProcLoopAnim:Stop()

		local parent = frame:GetParent()
		if parent._ProcGlow then
			parent._ProcGlow = nil
		end
	end,
	nil,
	function(frame)
		frame.ProcStart = frame:CreateTexture(nil, "ARTWORK")
		frame.ProcStart:SetBlendMode("ADD")
		frame.ProcStart:SetAtlas("UI-HUD-ActionBar-Proc-Start-Flipbook")
		frame.ProcStart:SetAlpha(1)
		frame.ProcStart:SetSize(150, 150)
		frame.ProcStart:SetPoint("CENTER")

		frame.ProcLoop = frame:CreateTexture(nil, "ARTWORK")
		frame.ProcLoop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
		frame.ProcLoop:SetAlpha(0)
		frame.ProcLoop:SetAllPoints()

		frame.ProcLoopAnim = frame:CreateAnimationGroup()
		frame.ProcLoopAnim:SetLooping("REPEAT")
		frame.ProcLoopAnim:SetToFinalAlpha(true)

		local alphaRepeat = frame.ProcLoopAnim:CreateAnimation("Alpha")
		alphaRepeat:SetChildKey("ProcLoop")
		alphaRepeat:SetFromAlpha(1)
		alphaRepeat:SetToAlpha(1)
		alphaRepeat:SetDuration(0.001)
		alphaRepeat:SetOrder(0)
		frame.ProcLoopAnim.alphaRepeat = alphaRepeat

		local flipbookRepeat = frame.ProcLoopAnim:CreateAnimation("FlipBook")
		flipbookRepeat:SetChildKey("ProcLoop")
		flipbookRepeat:SetDuration(1)
		flipbookRepeat:SetOrder(0)
		flipbookRepeat:SetFlipBookRows(6)
		flipbookRepeat:SetFlipBookColumns(5)
		flipbookRepeat:SetFlipBookFrames(30)
		flipbookRepeat:SetFlipBookFrameWidth(0)
		flipbookRepeat:SetFlipBookFrameHeight(0)
		frame.ProcLoopAnim.flipbookRepeat = flipbookRepeat

		frame.ProcStartAnim = frame:CreateAnimationGroup()
		frame.ProcStartAnim:SetToFinalAlpha(true)

		local flipbookStartAlphaIn = frame.ProcStartAnim:CreateAnimation("Alpha")
		flipbookStartAlphaIn:SetChildKey("ProcStart")
		flipbookStartAlphaIn:SetDuration(0.001)
		flipbookStartAlphaIn:SetOrder(0)
		flipbookStartAlphaIn:SetFromAlpha(1)
		flipbookStartAlphaIn:SetToAlpha(1)

		local flipbookStart = frame.ProcStartAnim:CreateAnimation("FlipBook")
		flipbookStart:SetChildKey("ProcStart")
		flipbookStart:SetDuration(0.7)
		flipbookStart:SetOrder(1)
		flipbookStart:SetFlipBookRows(6)
		flipbookStart:SetFlipBookColumns(5)
		flipbookStart:SetFlipBookFrames(30)
		flipbookStart:SetFlipBookFrameWidth(0)
		flipbookStart:SetFlipBookFrameHeight(0)

		local flipbookStartAlphaOut = frame.ProcStartAnim:CreateAnimation("Alpha")
		flipbookStartAlphaOut:SetChildKey("ProcStart")
		flipbookStartAlphaOut:SetDuration(0.001)
		flipbookStartAlphaOut:SetOrder(2)
		flipbookStartAlphaOut:SetFromAlpha(1)
		flipbookStartAlphaOut:SetToAlpha(0)

		frame.ProcStartAnim.flipbookStart = flipbookStart
	end
)

function Private.Glows.ProcGlow_Start(frame, width, height)
	---@type ProcGlowFrame?
	local glowFrame = frame._ProcGlow

	if frame._ProcGlow == nil then
		frame._ProcGlow = ProcGlowPool:Acquire()
		glowFrame = frame._ProcGlow
	end

	assert(glowFrame ~= nil)

	glowFrame:SetParent(frame)
	glowFrame:SetFrameLevel(frame:GetFrameLevel() + 8)

	local xOffset = width * 0.2
	local yOffset = height * 0.2
	glowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -xOffset, yOffset)
	glowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", xOffset, -yOffset)

	glowFrame:SetScript("OnHide", function(self)
		if self.ProcStartAnim:IsPlaying() then
			self.ProcStartAnim:Stop()
		end

		if self.ProcLoopAnim:IsPlaying() then
			self.ProcLoopAnim:Stop()
		end
	end)

	glowFrame:SetScript("OnShow", function(self)
		if not self.ProcStartAnim:IsPlaying() and not self.ProcLoopAnim:IsPlaying() then
			self.ProcStart:SetSize((width * 1.4 / 42 * 150) / 1.4, (height * 1.4 / 42 * 150) / 1.4)
			self.ProcStart:Show()
			self.ProcLoop:Hide()
			self.ProcStartAnim:Play()
		end
	end)

	glowFrame.ProcStartAnim:SetScript("OnFinished", function()
		glowFrame.ProcLoopAnim:Play()
		glowFrame.ProcLoop:Show()
	end)
	glowFrame.ProcStart:SetDesaturated(nil)
	glowFrame.ProcStart:SetVertexColor(1, 1, 1, 1)
	glowFrame.ProcLoop:SetDesaturated(nil)
	glowFrame.ProcLoop:SetVertexColor(1, 1, 1, 1)

	glowFrame.ProcLoopAnim.flipbookRepeat:SetDuration(1)

	glowFrame:Show()
end

function Private.Glows.ProcGlow_Stop(frame)
	if frame._ProcGlow then
		ProcGlowPool:Release(frame._ProcGlow)
	end
end
