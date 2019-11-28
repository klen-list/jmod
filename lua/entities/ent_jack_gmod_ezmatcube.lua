-- Jackarunda 2019
AddCSLuaFile()
ENT.Type="anim"
ENT.Author = "TheOnly8Z"
ENT.PrintName="EZ Material Cube"
ENT.Spawnable=false

ENT.MaterialType = ""
ENT.Large = false

if SERVER then

	function ENT:SpawnFunction(ply,tr)
		local SpawnPos=tr.HitPos+tr.HitNormal*10
		local ent=ents.Create(self.ClassName)
		ent:SetAngles(Angle(0,0,0))
		ent:SetPos(SpawnPos)
		ent.Owner=ply
		ent:Spawn()
		ent:Activate()
		return ent
	end
	
	function ENT:Initialize()
	
		self:SetModel(self.Large and "models/hunter/blocks/cube05x05x05.mdl" or "models/hunter/blocks/cube025x025x025.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)	
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)

		self.NextLoad=0
		self.Loaded=false
		
		if JMod_MaterialTypes[self.MaterialType] then 
			if self.MaterialType == "organic" and self.Flesh then
				self:SetMaterial("models/flesh")
				self:GetPhysicsObject():SetMaterial("flesh")
				self.ColSound = "Flesh_Bloody.ImpactHard"
			else
				self:SetMaterial(table.Random(JMod_MaterialTypes[self.MaterialType].Material))
				self:GetPhysicsObject():SetMaterial(JMod_MaterialTypes[self.MaterialType].PhysMaterial)
				self.ColSound = JMod_MaterialTypes[self.MaterialType].ColSound
			end
		end

		self:GetPhysicsObject():SetMass(self.Large and 80 or 10)
		self:GetPhysicsObject():Wake()
	end
	
	function ENT:Use(activator)
	
		if(self.Hint)then JMod_Hint(activator,self.Hint) end
		
		if((self.AltUse)and(activator:KeyDown(IN_WALK)))then
			self:AltUse(activator)
		else
			activator:PickupObject(self)
		end
		
	end
	
	function ENT:PhysicsCollide(data,physobj)
	
		if self.Loaded then return end
		
		if data.DeltaTime>0.2 and data.Speed > 25 then
			self:EmitSound(self.ColSound or "Plastic_Box.ImpactHard")
		end

	end

elseif CLIENT then
	
end