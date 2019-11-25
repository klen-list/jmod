ENT.Type 			= "anim"
ENT.PrintName		= "EZ Generator"
ENT.Author			= "Jackarunda, TheOnly8Z"
ENT.Category			= "JMod - EZ"
ENT.Information         = ""
ENT.Spawnable			= true
ENT.AdminSpawnable		= true

-- TODO Make these configurable (and maybe upgradable?)
ENT.MaxFuel = 1000
ENT.MaxPower = 1000

ENT.EZconsumes = {"fuel"}
ENT.BatteryEnt = "ent_jack_gmod_ezbattery"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Fuel")
	self:NetworkVar("Int", 1, "Power")
	self:NetworkVar("Int", 2, "State")
end