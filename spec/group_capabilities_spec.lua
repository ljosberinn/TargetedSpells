---@diagnostic disable: undefined-global, undefined-field

-- Contract for Private.Groups.ComputeCapabilities — the pure reduction the Driver
-- caches in place of the retired AnyGroup* scans. Each case isolates one rule, so a
-- failure points at a single capability.

local b = require("spec.bootstrap")
local Private = b.Private
local Enum = Private.Enum
local Template = Enum.Template
local Element = Enum.Element
local BarColorMode = Enum.BarColorMode

-- Minimal group shapes ComputeCapabilities reads. Each helper is the smallest group
-- that should flip exactly one capability, so a failing case points at one rule.
local function enabledBar(coreOverrides, elementOverrides)
	local elements = {
		[Element.ProgressBar] = coreOverrides or {},
	}

	if elementOverrides then
		for element, values in pairs(elementOverrides) do
			elements[element] = values
		end
	end

	return { Enabled = true, Template = Template.Bar, Elements = elements }
end

describe("Groups.ComputeCapabilities", function()
	it("an empty group set is all-false", function()
		assert.same({
			enabled = false,
			usesInterruptibility = false,
			usesShield = false,
			showsTargetMarker = false,
			indicatesInterrupts = false,
		}, Private.Groups.ComputeCapabilities({}))
	end)

	it("enabled is true when any group is Enabled", function()
		local capabilities = Private.Groups.ComputeCapabilities({
			[1] = { Enabled = false, Template = Template.Icon, Elements = {} },
			[2] = { Enabled = true, Template = Template.Icon, Elements = {} },
		})
		assert.is_true(capabilities.enabled)
	end)

	it("usesInterruptibility needs an enabled Bar coloured by interruptibility", function()
		local capabilities = Private.Groups.ComputeCapabilities({
			[1] = enabledBar({ barColorMode = BarColorMode.Interruptibility }),
		})
		assert.is_true(capabilities.usesInterruptibility)
	end)

	it("usesInterruptibility ignores a disabled Bar", function()
		local group = enabledBar({ barColorMode = BarColorMode.Interruptibility })
		group.Enabled = false
		local capabilities = Private.Groups.ComputeCapabilities({ [1] = group })
		assert.is_false(capabilities.usesInterruptibility)
	end)

	it("usesShield needs an enabled Bar with an active InterruptShield", function()
		local capabilities = Private.Groups.ComputeCapabilities({
			[1] = enabledBar(nil, { [Element.InterruptShield] = { active = true } }),
		})
		assert.is_true(capabilities.usesShield)
	end)

	it("usesShield is false when the shield element is present but inactive", function()
		local capabilities = Private.Groups.ComputeCapabilities({
			[1] = enabledBar(nil, { [Element.InterruptShield] = { active = false } }),
		})
		assert.is_false(capabilities.usesShield)
	end)

	it("usesShield is false when the bar carrying the shield is disabled", function()
		local group = enabledBar(nil, { [Element.InterruptShield] = { active = true } })
		group.Enabled = false
		assert.is_false(Private.Groups.ComputeCapabilities({ [1] = group }).usesShield)
	end)

	it("usesShield ignores an active shield on a non-bar (icon) group", function()
		assert.is_false(Private.Groups.ComputeCapabilities({
			[1] = { Enabled = true, Template = Template.Icon, Elements = { [Element.InterruptShield] = { active = true } } },
		}).usesShield)
	end)

	it("showsTargetMarker needs an enabled Bar with an active TargetMarker", function()
		local capabilities = Private.Groups.ComputeCapabilities({
			[1] = enabledBar(nil, { [Element.TargetMarker] = { active = true } }),
		})
		assert.is_true(capabilities.showsTargetMarker)
	end)

	it("indicatesInterrupts is independent of Enabled", function()
		local capabilities = Private.Groups.ComputeCapabilities({
			[1] = { Enabled = false, Template = Template.Icon, Elements = {}, IndicateInterrupts = true },
		})
		assert.is_true(capabilities.indicatesInterrupts)
	end)
end)
