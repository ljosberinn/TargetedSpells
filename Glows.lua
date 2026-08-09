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

---@diagnostic disable: undefined-field, inject-field

---@type string, TargetedSpells
local _, Private = ...

---@diagnostic disable-next-line: missing-fields
Private.Glows = {}

local textureList = {
	empty = [[Interface\AdventureMap\BrokenIsles\AM_29]],
	white = [[Interface\BUTTONS\WHITE8X8]],
	shine = [[Interface\Artifacts\Artifacts]],
}
local shineCoords = { 0.8115234375, 0.9169921875, 0.8798828125, 0.9853515625 }
local GlowParent = UIParent

local GlowMaskPool = {
	createFunc = function(self)
		return self.parent:CreateMaskTexture()
	end,
	resetFunc = function(_, mask)
		mask:Hide()
		mask:ClearAllPoints()
	end,
	AddObject = function(self, object)
		self.activeObjects[object] = true
		self.activeObjectCount = self.activeObjectCount + 1
	end,
	ReclaimObject = function(self, object)
		tinsert(self.inactiveObjects, object)
		self.activeObjects[object] = nil
		self.activeObjectCount = self.activeObjectCount - 1
	end,
	Release = function(self, object)
		local active = self.activeObjects[object] ~= nil

		if active then
			self:resetFunc(object)
			self:ReclaimObject(object)
		end

		return active
	end,
	Acquire = function(self)
		local object = tremove(self.inactiveObjects)
		local isNew = object == nil

		if isNew then
			object = self:createFunc()
			self:resetFunc(object, isNew)
		end

		self:AddObject(object)

		return object, isNew
	end,
	Init = function(self, parent)
		self.activeObjects = {}
		self.inactiveObjects = {}
		self.activeObjectCount = 0
		self.parent = parent
	end,
}

GlowMaskPool:Init(GlowParent)

local GlowTexPool = CreateTexturePool(
	GlowParent,
	"ARTWORK",
	7,
	nil,
	---@param tex Texture
	function(_, tex)
		local maskNum = tex:GetNumMaskTextures()

		for Idx = maskNum, 1, -1 do
			tex:RemoveMaskTexture(tex:GetMaskTexture(Idx))
		end

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

		if frame.bg then
			GlowTexPool:Release(frame.bg)
			frame.bg = nil
		end

		if frame.masks then
			for _, mask in pairs(frame.masks) do
				GlowMaskPool:Release(mask)
			end
			frame.masks = nil
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
	local th = 1

	---@param progress number
	---@param size number
	---@param thickness number
	---@param phases table
	---@return number
	local function PCalc1(progress, size, thickness, phases)
		local coord

		if progress > phases[3] or progress < phases[0] then
			coord = 0
		elseif progress > phases[2] then
			coord = size - thickness - (progress - phases[2]) / (phases[3] - phases[2]) * (size - thickness)
		elseif progress > phases[1] then
			coord = size - thickness
		else
			coord = (progress - phases[0]) / (phases[1] - phases[0]) * (size - thickness)
		end

		return math.floor(coord + 0.5)
	end

	---@param progress number
	---@param size number
	---@param thickness number
	---@param phases table
	---@return number
	local function PCalc2(progress, size, thickness, phases)
		local coord

		if progress > phases[3] then
			coord = size - thickness - (progress - phases[3]) / (phases[0] + 1 - phases[3]) * (size - thickness)
		elseif progress > phases[2] then
			coord = size - thickness
		elseif progress > phases[1] then
			coord = (progress - phases[1]) / (phases[2] - phases[1]) * (size - thickness)
		elseif progress > phases[0] then
			coord = 0
		else
			coord = size - thickness - (progress + 1 - phases[3]) / (phases[0] + 1 - phases[3]) * (size - thickness)
		end

		return math.floor(coord + 0.5)
	end

	---@param self GlowFrame
	---@param elapsed number
	local function PUpdate(self, elapsed)
		self.throttle = (self.throttle or 0) + elapsed

		if self.throttle < GLOW_UPDATE_INTERVAL then
			return
		end

		local step = self.throttle
		self.throttle = 0

		self.timer = self.timer + step / self.info.period

		if self.timer > 1 or self.timer < -1 then
			self.timer = self.timer % 1
		end

		local progress = self.timer
		local width = self.info.width
		local height = self.info.height

		if self.info.needsUpdate then
			self.info.needsUpdate = nil
			local perimeter = 2 * (width + height)

			if not (perimeter > 0) then
				return
			end

			self.info.width = width
			self.info.height = height
			self.info.pTLx = {
				[0] = (height + self.info.length / 2) / perimeter,
				[1] = (height + width + self.info.length / 2) / perimeter,
				[2] = (2 * height + width - self.info.length / 2) / perimeter,
				[3] = 1 - self.info.length / 2 / perimeter,
			}
			self.info.pTLy = {
				[0] = (height - self.info.length / 2) / perimeter,
				[1] = (height + width + self.info.length / 2) / perimeter,
				[2] = (height * 2 + width + self.info.length / 2) / perimeter,
				[3] = 1 - self.info.length / 2 / perimeter,
			}
			self.info.pBRx = {
				[0] = self.info.length / 2 / perimeter,
				[1] = (height - self.info.length / 2) / perimeter,
				[2] = (height + width - self.info.length / 2) / perimeter,
				[3] = (height * 2 + width + self.info.length / 2) / perimeter,
			}
			self.info.pBRy = {
				[0] = self.info.length / 2 / perimeter,
				[1] = (height + self.info.length / 2) / perimeter,
				[2] = (height + width - self.info.length / 2) / perimeter,
				[3] = (height * 2 + width - self.info.length / 2) / perimeter,
			}
		end

		if self:IsShown() then
			if not (self.masks[1]:IsShown()) then
				self.masks[1]:Show()
				self.masks[1]:SetPoint("TOPLEFT", self, "TOPLEFT", self.info.th, -self.info.th)
				self.masks[1]:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.info.th, self.info.th)
			end

			if self.masks[2] and not (self.masks[2]:IsShown()) then
				self.masks[2]:Show()
				self.masks[2]:SetPoint("TOPLEFT", self, "TOPLEFT", self.info.th + 1, -self.info.th - 1)
				self.masks[2]:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.info.th - 1, self.info.th + 1)
			end

			if self.bg and not (self.bg:IsShown()) then
				self.bg:Show()
			end

			for index, line in pairs(self.textures) do
				line:SetPoint(
					"TOPLEFT",
					self,
					"TOPLEFT",
					PCalc1((progress + self.info.step * (index - 1)) % 1, width, self.info.th, self.info.pTLx),
					-PCalc2((progress + self.info.step * (index - 1)) % 1, height, self.info.th, self.info.pTLy)
				)
				line:SetPoint(
					"BOTTOMRIGHT",
					self,
					"TOPLEFT",
					self.info.th
					+ PCalc2((progress + self.info.step * (index - 1)) % 1, width, self.info.th, self.info.pBRx),
					-height
					+ PCalc1((progress + self.info.step * (index - 1)) % 1, height, self.info.th, self.info.pBRy)
				)
			end
		end
	end

	function Private.Glows.PixelGlow_Start(frame, width, height)
		local length = math.floor((width + height) * (2 / count - 0.1))
		length = min(length, min(width, height))

		local GlowFrame = AddFrameAndTex(frame, color, "_PixelGlow", count, textureList.white, { 0, 1, 0, 1 })

		if not GlowFrame.masks then
			GlowFrame.masks = {}
		end

		if not GlowFrame.masks[1] then
			GlowFrame.masks[1] = GlowMaskPool:Acquire()
			GlowFrame.masks[1]:SetTexture(textureList.empty, "CLAMPTOWHITE", "CLAMPTOWHITE")
			GlowFrame.masks[1]:Show()
		end

		GlowFrame.masks[1]:SetPoint("TOPLEFT", GlowFrame, "TOPLEFT", th, -th)
		GlowFrame.masks[1]:SetPoint("BOTTOMRIGHT", GlowFrame, "BOTTOMRIGHT", -th, th)

		-- if not (border == false) then
		if not GlowFrame.masks[2] then
			GlowFrame.masks[2] = GlowMaskPool:Acquire()
			GlowFrame.masks[2]:SetTexture(textureList.empty, "CLAMPTOWHITE", "CLAMPTOWHITE")
		end

		GlowFrame.masks[2]:SetPoint("TOPLEFT", GlowFrame, "TOPLEFT", th + 1, -th - 1)
		GlowFrame.masks[2]:SetPoint("BOTTOMRIGHT", GlowFrame, "BOTTOMRIGHT", -th - 1, th + 1)

		if not GlowFrame.bg then
			GlowFrame.bg = GlowTexPool:Acquire()
			GlowFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
			GlowFrame.bg:SetParent(GlowFrame)
			GlowFrame.bg:SetAllPoints(GlowFrame)
			GlowFrame.bg:SetDrawLayer("ARTWORK", 6)
			GlowFrame.bg:AddMaskTexture(GlowFrame.masks[2])
		end

		for _, tex in pairs(GlowFrame.textures) do
			if tex:GetNumMaskTextures() < 1 then
				tex:AddMaskTexture(GlowFrame.masks[1])
			end
		end

		GlowFrame.timer = GlowFrame.timer or 0
		GlowFrame.throttle = 0
		GlowFrame.info = GlowFrame.info or {}
		GlowFrame.info.step = 1 / count
		GlowFrame.info.period = 4
		GlowFrame.info.th = th
		GlowFrame.info.length = length
		if GlowFrame.info.width ~= width or GlowFrame.info.height ~= height then
			GlowFrame.info.width = width
			GlowFrame.info.height = height
			GlowFrame.info.needsUpdate = true
		end

		PUpdate(GlowFrame, GLOW_UPDATE_INTERVAL)

		GlowFrame:SetScript("OnUpdate", PUpdate)
	end
end

function Private.Glows.PixelGlow_Stop(frame)
	if frame._PixelGlow then
		GlowFramePool:Release(frame._PixelGlow)
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
