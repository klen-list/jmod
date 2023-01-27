-- Jackarunda, AdventureBoots 2023
AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "EZ Fabricator"
ENT.Author = "Jackarunda, AdventureBoots"
ENT.Category = "JMod - EZ Misc."
ENT.Information = "glhfggwpezpznore"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Model = "models/jmod/machines/parts_machine.mdl"
ENT.Mass = 1000
ENT.JModPreferredCarryAngles = Angle(0, 180, 0)
ENT.EZconsumes = {
	JMod.EZ_RESOURCE_TYPES.BASICPARTS,
	JMod.EZ_RESOURCE_TYPES.POWER
}
ENT.Base = "ent_jack_gmod_ezmachine_base"
---
ENT.StaticPerfSpecs={
	MaxDurability = 100,
	Armor = .8,
	MaxElectricity = 300,
	MaxGas = 300,
	MaxChemicals = 100,
	MaxWater = 100
}

local STATE_BROKEN, STATE_FINE = -1, 0

function ENT:CustomSetupDataTables()
	self:NetworkVar("Float", 1, "Gas")
	self:NetworkVar("Float", 2, "Water")
	self:NetworkVar("Float", 3, "Chemicals")
end

if(SERVER)then
	function ENT:CustomInit()
		local phys = self:GetPhysicsObject()
		if phys:IsValid()then
			phys:SetBuoyancyRatio(.3)
		end
		---
		if not(self.Owner)then self:SetColor(Color(45, 101, 153)) end
		self:UpdateConfig()
		---
		self:SetGas(self.MaxGas)
		self:SetChemicals(self.MaxChemicals)
		self:SetWater(self.MaxWater)
	end

	function ENT:UpdateConfig()
		self.Craftables = {}
		for name, info in pairs(JMod.Config.Craftables)do
			if(info.craftingType == "adv_workbench")then
				-- we store this here for client transmission later
				-- because we can't rely on the client having the config
				local infoCopy = table.FullCopy(info)
				infoCopy.name = name
				self.Craftables[name] = info
			end
		end
	end

	function ENT:BuildEffect(pos)
		local Scale = .5
		local effectdata = EffectData()
		effectdata:SetOrigin(pos + VectorRand())
		effectdata:SetNormal((VectorRand() + Vector(0, 0, 1)):GetNormalized())
		effectdata:SetMagnitude(math.Rand(1, 2) * Scale) --amount and shoot hardness
		effectdata:SetScale(math.Rand(.5, 1.5) * Scale) --length of strands
		effectdata:SetRadius(math.Rand(2, 4) * Scale) --thickness of strands
		util.Effect("Sparks", effectdata,true,true)
		sound.Play("snds_jack_gmod/ez_tools/hit.wav", pos + VectorRand(), 60, math.random(80, 120))
		sound.Play("snds_jack_gmod/ez_tools/"..math.random(1, 27)..".wav", pos, 60, math.random(80, 120))
		local eff = EffectData()
		eff:SetOrigin(pos + VectorRand())
		eff:SetScale(Scale)
		util.Effect("eff_jack_gmod_ezbuildsmoke", eff, true, true)
		-- todo: useEffects
	end

	function ENT:Use(activator)
		if(self:GetState() == STATE_FINE)then
			if(self:GetElectricity() > 0)then
				net.Start("JMod_EZworkbench")
				net.WriteEntity(self)
				net.WriteTable(self.Craftables)
				net.Send(activator)
			else
				JMod.Hint(activator, "refill")
			end
		else
			JMod.Hint(activator, "destroyed")
		end
	end

	function ENT:TryBuild(itemName, ply)
		local ItemInfo = self.Craftables[itemName]

		if(JMod.HaveResourcesToPerformTask(nil, nil, ItemInfo.craftingReqs, self))then
			local override, msg = hook.Run("JMod_CanWorkbenchBuild", ply, workbench, itemName)
			if override == false then
				ply:PrintMessage(HUD_PRINTCENTER, msg or "cannot build")
				return
			end
			local Pos, Ang, BuildSteps = self:GetPos()+self:GetUp()*55+self:GetForward()*0-self:GetRight()*5,self:GetAngles(),10
			JMod.ConsumeResourcesInRange(ItemInfo.craftingReqs,Pos,nil,self,true)
			timer.Simple(1,function()
				if(IsValid(self))then
					for i=1,BuildSteps do
						timer.Simple(i/100,function()
							if(IsValid(self))then
								if(i<BuildSteps)then
									sound.Play("snds_jack_gmod/ez_tools/"..math.random(1,27)..".wav",Pos,60,math.random(80,120))
								else
									local StringParts=string.Explode(" ", ItemInfo.results)
									if((StringParts[1])and(StringParts[1] == "FUNC"))then
										local FuncName = StringParts[2]
										if((JMod.LuaConfig) and (JMod.LuaConfig.BuildFuncs) and (JMod.LuaConfig.BuildFuncs[FuncName]))then
											local Ent = JMod.LuaConfig.BuildFuncs[FuncName](ply, Pos, Ang)
											if(Ent)then
												if(Ent:GetPhysicsObject():GetMass() <= 15)then ply:PickupObject(Ent) end
											end
										else
											print("JMOD WORKBENCH ERROR: garrysmod/lua/autorun/JMod.LuaConfig.lua is missing, corrupt, or doesn't have an entry for that build function")
										end
									else
										local Ent = ents.Create(ItemInfo.results)
										Ent:SetPos(Pos)
										Ent:SetAngles(Ang)
										JMod.SetOwner(Ent, ply)
										Ent:Spawn()
										Ent:Activate()
										if(Ent:GetPhysicsObject():GetMass() <= 15)then ply:PickupObject(Ent) end
									end
									self:BuildEffect(Pos)
									self:ConsumeElectricity(5)
								end
							end
						end)
					end
				end
			end)
		else
			JMod.Hint(ply,"missing supplies")
		end
	end

elseif(CLIENT)then

	function ENT:CustomInit()
		self.ZipZoop = JMod.MakeModel(self, "models/props_combine/combinetrain01a.mdl", "phoenix_storms/chrome", .05)
	end

	local ScreenOneMat = Material("models/jmod/machines/parts_machine/screen1_on")
	local ScreenTwoMat = Material("models/jmod/machines/parts_machine/screen2_on")
	local ScreenThreeMat = Material("models/jmod/machines/parts_machine/screen3_on")
	local ScreenFourMat = Material("models/jmod/machines/parts_machine/screen4_on")
	function ENT:DrawTranslucent()
		local SelfPos, SelfAng, FT = self:GetPos(), self:GetAngles(), FrameTime()
		local Up, Right, Forward = SelfAng:Up(), SelfAng:Right(), SelfAng:Forward()
		---
		local BasePos = SelfPos + Up * 60
		local Obscured = util.TraceLine({
			start = EyePos(),
			endpos = BasePos,
			filter = {LocalPlayer(), self},
			mask = MASK_OPAQUE
		}).Hit

		local Closeness = LocalPlayer():GetFOV()*(EyePos():Distance(SelfPos))
		local DetailDraw = Closeness < 36000 -- cutoff point is 400 units when the fov is 90 degrees
		if((not(DetailDraw))and(Obscured))then return end -- if player is far and sentry is obscured, draw nothing
		if(Obscured)then DetailDraw=false end -- if obscured, at least disable details
		if(self:GetState()<0)then DetailDraw=false end

		---
		self:DrawModel()
		---
		if(DetailDraw)then
			if(self:GetElectricity() > 0)then
				local DisplayAng = SelfAng:GetCopy()
				DisplayAng:RotateAroundAxis(Forward, 90)
				local Opacity = math.random(50, 200)
				local ElecFrac = self:GetElectricity()/self.MaxElectricity
				local R,G,B = JMod.GoodBadColor(ElecFrac)

				cam.Start3D2D(BasePos + Right * 15.8 + Forward * 11.5 + Up * -13, DisplayAng, .04)
					draw.SimpleTextOutlined("POWER "..math.Round(ElecFrac*100).."%","JMod-Display",0,60,Color(R,G,B,Opacity),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,3,Color(0,0,0,Opacity))
				cam.End3D2D()

				local DisplayAng = SelfAng:GetCopy()
				DisplayAng:RotateAroundAxis(Forward, 90)
				DisplayAng:RotateAroundAxis(Up, 180)
				cam.Start3D2D(BasePos + Right * -54 + Forward * 8 + Up * -30, DisplayAng, .05)
					draw.SimpleTextOutlined("POWER "..math.Round(ElecFrac*100).."%","JMod-Display",-600,60,Color(R,G,B,Opacity),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,3,Color(0,0,0,Opacity))
				cam.End3D2D()

				-- because Source 2007 is impossibly stupid with its use of $selfillum and color tinting, we have to manually draw the screens as quads
				DisplayAng=SelfAng:GetCopy()
				DisplayAng:RotateAroundAxis(Up, -90)
				DisplayAng:RotateAroundAxis(Right, 180)
				DisplayAng:RotateAroundAxis(Forward, -4.5)
				render.SetMaterial(ScreenOneMat)
				render.DrawQuadEasy(BasePos + Forward * 26.2 + Right * 16 - Up * 17.5, DisplayAng:Forward(), 12.5, 7, Color(255, 255, 255, 255), DisplayAng.r)
				--
				DisplayAng=SelfAng:GetCopy()
				DisplayAng:RotateAroundAxis(Up, -90)
				DisplayAng:RotateAroundAxis(Right, 180)
				DisplayAng:RotateAroundAxis(Forward, -19)
				render.SetMaterial(ScreenTwoMat)
				render.DrawQuadEasy(BasePos - Forward * 13.4 + Right * 22.1 - Up * 31.2, DisplayAng:Forward(), 9.5, 4.5, Color(255, 255, 255, 255), DisplayAng.r)
				--
				DisplayAng=SelfAng:GetCopy()
				DisplayAng:RotateAroundAxis(Up, -90)
				DisplayAng:RotateAroundAxis(Right, 180)
				DisplayAng:RotateAroundAxis(Forward, -36)
				render.SetMaterial(ScreenThreeMat)
				render.DrawQuadEasy(BasePos + Forward * 53.8 + Right * 25 - Up * 28, DisplayAng:Forward(), 11.2, 5.7, Color(170, 170, 170, 255), DisplayAng.r)
			end

			local DisplayAng=SelfAng:GetCopy()
			DisplayAng:RotateAroundAxis(Up, 0)
			DisplayAng:RotateAroundAxis(Right, 180)
			DisplayAng:RotateAroundAxis(Forward, -89)
			JMod.RenderModel(self.ZipZoop, BasePos - Forward * 15 - Right * 9 - Up * 19, DisplayAng)
		end
	end
	language.Add("ent_jack_gmod_ezfabricator","EZ Fabricator")
end