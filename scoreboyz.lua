if not game:IsLoaded() then game.Loaded:Wait() end
local P=game:GetService('Players');while not P.LocalPlayer or not workspace.CurrentCamera do task.wait() end
local U=game:GetService('UserInputService');local R=game:GetService('RunService');local H=game:GetService('HttpService')
local L=game:GetService('Lighting');local RS=game:GetService('ReplicatedStorage')
local LP=P.LocalPlayer;local Cam=workspace.CurrentCamera

-- Destroy PlayerGui.VendingMachine.VendingMachine on start (no GUI toggle)
task.spawn(function()
	pcall(function()
		local pg = LP:WaitForChild("PlayerGui",10)
		if not pg then return end
		local vmRoot = pg:FindFirstChild("VendingMachine")
		local vm = vmRoot and vmRoot:FindFirstChild("VendingMachine")
		if vm then vm:Destroy() end
	end)
end)

local WURL=(getgenv and getgenv().Webhook)or'';local WID=(getgenv and tostring(getgenv().UserID))or''
local function req()return(syn and syn.request)or(http and http.request)or(getgenv and getgenv().request)or http_request or(fluxus and fluxus.request)end
local function webhook(user,title,desc,ping)
	if WURL=='' then return end
	local r=req();if not r then return end
	local content,allowed;if ping and tostring(ping)~='' then content='<@'..tostring(ping)..'>';allowed={tostring(ping)} end
	local pl={username=user,content=content,embeds={{title=title,description=desc,color=16711680,footer={text='Roblox • '..os.date('%H:%M')}}},allowed_mentions={parse={},users=allowed or {}}}
	pcall(function()r({Url=WURL,Method='POST',Headers={['Content-Type']='application/json'},Body=H:JSONEncode(pl)})end)
end
local function deathWH(n,k)webhook('Death Bot','⚠️ Player Killed!',n..' was killed.',WID)end
local function panicWH(n)webhook('Panic Bot','Panic Activated',n..' Triggered Panic',WID)end

local cfg={
	FireBallAimbot=false,FireBallAimbotCity=false,UniversalFireBallAimbot=false,SmartPanic=false,
	DeathWebhook=true,PanicWebhook=false,GraphicsOptimization=false,GraphicsOptimizationAdvanced=false,
	UltimateAFKOptimization=false,NoClip=false,PlayerESP=false,MobESP=false,AutoWashDishes=false,
	AutoNinjaSideTask=false,AutoAnimatronicsSideTask=false,AutoMutantsSideTask=false,DualExoticShop=false,
	VendingPotionAutoBuy=false,RemoveMapClutter=false,StatWebhook15m=false,KillAura=false,StatGui=false,
	AutoInvisible=false,AutoResize=false,AutoFly=false,HealthExploit=false,GammaAimbot=false,InfiniteZoom=false,
	AutoConsumePower=false,AutoConsumeHealth=false,AutoConsumeDefense=false,AutoConsumePsychic=false,AutoConsumeMagic=false,AutoConsumeMobility=false,AutoConsumeSuper=false,QuickTeleports=false,
	KickOnUntrustedPlayers=false,AutoBlock=false,CombatLog=false,
	UFAOrderedMobs={},
	fireballCooldown=0.1,cityFireballCooldown=0.5,universalFireballInterval=1.0,HideGUIKey='RightControl',
}
local function save()pcall(function()writefile('SuperPowerLeague_Config.json',H:JSONEncode(cfg))end)end
local function load()pcall(function()if isfile('SuperPowerLeague_Config.json')then for k,v in pairs(H:JSONDecode(readfile('SuperPowerLeague_Config.json')))do cfg[k]=v end end end)end
load()
-- Migration from old UFASelectedMobs to new UFAOrderedMobs
if cfg.UFASelectedMobs and type(cfg.UFASelectedMobs) == "table" then
	cfg.UFAOrderedMobs = {}
	for mobName, selected in pairs(cfg.UFASelectedMobs) do
		if selected then table.insert(cfg.UFAOrderedMobs, mobName) end
	end
	cfg.UFASelectedMobs = nil
	save()
end
if type(cfg.UFASelectedMob)=="string" and cfg.UFASelectedMob~="" then
	cfg.UFAOrderedMobs = cfg.UFAOrderedMobs or {}
	if not table.find(cfg.UFAOrderedMobs, cfg.UFASelectedMob) then
		table.insert(cfg.UFAOrderedMobs, cfg.UFASelectedMob)
	end
	cfg.UFASelectedMob=nil
	save()
end
cfg.UFAOrderedMobs = cfg.UFAOrderedMobs or {}
local targetAttempts={}

-- persistent saved teleport
local SAVEP_FILE='SuperPowerLeague_SavePos.json'
local savedCFrame=nil
local function cfToTable(cf)local a={cf:GetComponents()};return a end
local function tableToCF(t)if type(t)=='table' and #t==12 then return CFrame.new(unpack(t)) end return nil end
local function persistSave(cf)local ok,err=pcall(function()writefile(SAVEP_FILE,H:JSONEncode(cfToTable(cf)))end)end
local function loadPersistedSave()if isfile(SAVEP_FILE)then local ok,data=pcall(function()return H:JSONDecode(readfile(SAVEP_FILE))end);if ok then local cf=tableToCF(data);if cf then savedCFrame=cf end end end end
loadPersistedSave()
-- Auto-teleport to saved position on execute (controlled by getgenv().TeleportOnStart)
task.spawn(function()
	if getgenv and getgenv().TeleportOnStart then
		local cf = savedCFrame
		if not cf then loadPersistedSave(); cf = savedCFrame end
		if cf then
			local char = LP.Character or LP.CharacterAdded:Wait()
			local hrp = char:WaitForChild("HumanoidRootPart", 10)
			if hrp then pcall(function() char:PivotTo(cf) end) end
		end
	end
end)

local TRUST_WHITELIST = { ["1nedu"]=true, ["209Flaw"]=true }
local function isTrustedPlayer(playerName) return TRUST_WHITELIST[playerName]==true end
local function kickUntrustedCheck()
	for _, player in ipairs(P:GetPlayers()) do
		if player~=LP then
			if not isTrustedPlayer(player.Name) then
				LP:Kick("Untrusted player detected in server.")
				return
			end
		end
	end
end
local function TKickUntrusted(on)
	cfg.KickOnUntrustedPlayers=on;save();getgenv().KickOnUntrustedPlayers=on
	if on then
		kickUntrustedCheck()
		P.PlayerAdded:Connect(function(player)
			if not isTrustedPlayer(player.Name) then
				LP:Kick("Untrusted player detected in server.")
			end
		end)
	end
end

-- Teleport exotic stores to specific positions instantly (height adjusted)
task.spawn(function()
	pcall(function()
		local exoticStore = workspace.Pads.ExoticStore["1"]
		local exoticStore2 = workspace.Pads.ExoticStore2["1"]
		local pos1 = Vector3.new(-167.33985900878906, 93824, 156.6094207763672)
		local pos2 = Vector3.new(-180.12326049804688, 93824, 134.66819763183594)
		exoticStore.CFrame = CFrame.new(pos1)
		exoticStore2.CFrame = CFrame.new(pos2)
	end)
end)

-- Train mobility
task.spawn(function()
	pcall(function()
		local args = {}
		while true do
			game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("Train", 9e9):WaitForChild("TrainMobility", 9e9):FireServer(unpack(args))
			task.wait(0.1)
		end
	end)
end)

local function charHum()local c=LP.Character or LP.CharacterAdded:Wait();return c,c:FindFirstChildOfClass('Humanoid'),c:FindFirstChild('HumanoidRootPart')end
local function ev(...)local n=RS;for _,p in ipairs({...})do n=n:WaitForChild(p,9e9)end;return n end
local function disableAimbots()
	if getgenv().UniversalFireBallAimbot or getgenv().FireBallAimbot or getgenv().FireBallAimbotCity then
		getgenv().UniversalFireBallAimbot=false;getgenv().FireBallAimbot=false;getgenv().FireBallAimbotCity=false
		cfg.UniversalFireBallAimbot=false;cfg.FireBallAimbot=false;cfg.FireBallAimbotCity=false;save()
	end
end

-- death + panic hooks (panic under 50% for webhook trigger baseline)
local lastPanicSentAt,PANIC_THRESHOLD,PANIC_COOLDOWN,REARM=0,0.5,5,0.95
local function initDeathPanic()
	local function hook(c)
		local h=c:WaitForChild('Humanoid',10);if not h then return end
		local lastD,dsent,armed=nil,false,true
		local lastP,MIN=0,5
		h.Died:Connect(function()
			if cfg.DeathWebhook and not dsent then dsent=true;disableAimbots();deathWH(LP.Name,(lastD and lastD.Name)or'Unknown') else disableAimbots() end
			armed=true
		end)
		h.HealthChanged:Connect(function(hp)
			local m=h.MaxHealth;if not m or m<=0 then return end
			local r,now=hp/m,os.clock()
			if r<=PANIC_THRESHOLD and armed then
				if(now-lastP)<MIN then return end;lastP=now;armed=false;disableAimbots()
			elseif r>=REARM then armed=true end
		end)
		task.defer(function()
			for _,p in ipairs(workspace:GetDescendants())do if p:IsA('BasePart')then p.Touched:Connect(function(hit)local pl=P:GetPlayerFromCharacter(hit.Parent);if pl then lastD=pl.Character end end)end end
		end)
	end
	if LP.Character then hook(LP.Character) end;LP.CharacterAdded:Connect(hook)
end
initDeathPanic()

getgenv().SmartPanic=cfg.SmartPanic and true or false
local function panicCF()return CFrame.new(Vector3.new(-167.33985900878906, 938243, 156.6094207763672))end
task.spawn(function()
	local last,armed=0,true
	while true do
		if getgenv().SmartPanic then
			local c,h=charHum();if h then local m=(h.MaxHealth and h.MaxHealth>0)and h.MaxHealth or 100;local now=os.clock()
				if armed and h.Health>0 and h.Health<=0.50*m and(now-last)>=1.5 then 
	local cf=panicCF()
	if cf and LP.Character then 
		pcall(function()LP.Character:PivotTo(cf)end)
		if cfg.PanicWebhook then panicWH(LP.Name) end
	end
	last=now
	armed=false
				elseif not armed and h.Health>=REARM*m then armed=true end
			end
		end
		task.wait(0.1)
	end
end)

local G=Instance.new('ScreenGui');G.Name='SuperPowerLeagueGUI';G.ZIndexBehavior=Enum.ZIndexBehavior.Global;G.IgnoreGuiInset=true;G.ResetOnSpawn=false;G.Enabled=false
local function parentGui(gui)local p=(gethui and gethui())or game:FindFirstChildOfClass('CoreGui')or LP:WaitForChild('PlayerGui');if syn and syn.protect_gui and p==game:GetService('CoreGui')then pcall(syn.protect_gui,gui)end gui.Parent=p end
parentGui(G)
local function mk(t,pr,par)local i=Instance.new(t);for k,v in pairs(pr or{})do i[k]=v end;if par then i.Parent=par end;return i end

-- Minimal Stat Screen (P to toggle)
do
	local player=LP
	local playerGui=player:WaitForChild("PlayerGui")
	local function formatNumber(n)n=tonumber(n)or 0;if n>=1e18 then return string.format('%.4fqn',n/1e18)end;if n>=1e15 then return string.format('%.4fqd',n/1e15)end;if n>=1e12 then return string.format('%.4ft',n/1e12)end
		if n>=1e9 then return string.format('%.4fb',n/1e9)end;if n>=1e6 then return string.format('%.4fm',n/1e6)end;if n>=1e3 then return string.format('%.4fk',n/1e3)end return tostring(n)end
	local function getNumberValue(c,n)if not c then return 0 end local v=c:FindFirstChild(n)if v and v:IsA('ValueBase')then return tonumber(v.Value)or 0 end return 0 end
	local function getStringValue(c,n)if not c then return '' end local v=c:FindFirstChild(n)if v and v:IsA('ValueBase')then return tostring(v.Value or'')end return '' end
	local function lightenColor(color,factor)factor=math.clamp(factor or 0.4,0,1)local r=color.R+(1-color.R)*factor local g=color.G+(1-color.G)*factor local b=color.B+(1-color.B)*factor return Color3.new(r,g,b)end
	local dataFolder=RS:WaitForChild("Data");local playerData=dataFolder:WaitForChild(player.Name);local statsFolder=playerData:WaitForChild("Stats")
	local screenGui=Instance.new("ScreenGui");screenGui.IgnoreGuiInset=true;screenGui.ResetOnSpawn=false;screenGui.Name="NeduStatsScreen";screenGui.Enabled=false;screenGui.Parent=playerGui
	local frame=Instance.new("Frame");frame.Size=UDim2.new(1,0,1,0);frame.BackgroundTransparency=0;frame.BackgroundColor3=Color3.new(0,0,0);frame.Parent=screenGui
	local layout=Instance.new("UIListLayout");layout.Parent=frame;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(0,10);layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.FillDirection=Enum.FillDirection.Vertical
	local function createLabel(key,title,base,lf,stroke)local lbl=Instance.new("TextLabel");lbl.Name=key;lbl.Size=UDim2.new(1,-80,0,56);lbl.BackgroundTransparency=1;lbl.Font=Enum.Font.GothamBold;lbl.TextXAlignment=Enum.TextXAlignment.Center;lbl.TextYAlignment=Enum.TextYAlignment.Center;lbl.TextSize=45;local fill=lightenColor(base,lf or 0.45);lbl.TextColor3=fill;lbl.TextStrokeTransparency=0;lbl.TextStrokeColor3=stroke or base;lbl.Text=title..": 0";lbl.Parent=frame;return lbl end
	local function createSeparator(name)local line=Instance.new("Frame");line.Name=name;line.Size=UDim2.new(1,0,0,2);line.BackgroundTransparency=0;line.BorderSizePixel=0;line.BackgroundColor3=Color3.fromRGB(255,255,255);line.Parent=frame;return line end
	local function createSmallLabel(key,title,base,lf,stroke)local lbl=Instance.new("TextLabel");lbl.Name=key;lbl.Size=UDim2.new(1,-80,0,28);lbl.BackgroundTransparency=1;lbl.Font=Enum.Font.GothamBold;lbl.TextXAlignment=Enum.TextXAlignment.Center;lbl.TextYAlignment=Enum.TextYAlignment.Center;lbl.TextSize=24;local fill=lightenColor(base,lf or 0.45);lbl.TextColor3=fill;lbl.TextStrokeTransparency=0.25;lbl.TextStrokeColor3=stroke or base;lbl.Text=title..": 0";lbl.Parent=frame;return lbl end
	local function createBoostRow()local row=Instance.new("Frame");row.Name="BoostRow";row.Size=UDim2.new(1,-80,0,28);row.BackgroundTransparency=1;row.Parent=frame;local hlist=Instance.new("UIListLayout");hlist.Parent=row;hlist.FillDirection=Enum.FillDirection.Horizontal;hlist.HorizontalAlignment=Enum.HorizontalAlignment.Center;hlist.VerticalAlignment=Enum.VerticalAlignment.Center;hlist.Padding=UDim.new(0,8);hlist.SortOrder=Enum.SortOrder.LayoutOrder;return row end
	local function createBoostLabel(i,parent)local lbl=Instance.new("TextLabel");lbl.Name="Boost"..i;lbl.BackgroundTransparency=1;lbl.AutomaticSize=Enum.AutomaticSize.XY;lbl.Size=UDim2.new(0,0,0,28);lbl.Font=Enum.Font.GothamBold;lbl.TextSize=24;lbl.TextXAlignment=Enum.TextXAlignment.Center;lbl.TextYAlignment=Enum.TextYAlignment.Center;lbl.TextColor3=Color3.fromRGB(255,255,255);lbl.TextStrokeTransparency=0.25;lbl.TextStrokeColor3=Color3.fromRGB(200,200,200);lbl.Text="";lbl.Visible=false;lbl.Parent=parent;return lbl end
	local STAT_COLORS={Power=Color3.fromRGB(255,80,80),Health=Color3.fromRGB(80,255,80),Defense=Color3.fromRGB(80,80,255),Psychics=Color3.fromRGB(160,80,200),Magic=Color3.fromRGB(255,140,200),Mobility=Color3.fromRGB(255,255,120),Tokens=Color3.fromRGB(255,170,0)}
	local labels={Timer=createLabel("Timer","",Color3.fromRGB(255,255,255)),SepTop=createSeparator("SepTop"),Training=createLabel("Training","📋 Training",Color3.fromRGB(255,255,255)),SepBottom=createSeparator("SepBottom")}
	local boostRow=createBoostRow()local BOOST_EMOJIS={"💪","❤️","🛡️","🔮","✨","💨"}local boostLabels={}for i=1,6 do boostLabels[i]=createBoostLabel(i,boostRow)end
	labels.Tokens=createSmallLabel("Tokens","💰 Tokens",Color3.fromRGB(255,170,0),0.25,Color3.fromRGB(200,120,0))
	labels.Power=createLabel("Power","💪 Power",Color3.fromRGB(255,80,80));labels.Health=createLabel("Health","❤️ Health",Color3.fromRGB(80,255,80));labels.Defense=createLabel("Defense","🛡️ Defense",Color3.fromRGB(80,80,255));labels.Psychics=createLabel("Psychics","🔮 Psychics",Color3.fromRGB(160,80,200));labels.Magic=createLabel("Magic","✨ Magic",Color3.fromRGB(255,140,200));labels.Mobility=createLabel("Mobility","💨 Mobility",Color3.fromRGB(255,255,120));labels.TotalPower=createLabel("TotalPower","📊 Total Power",Color3.fromRGB(255,255,255));labels.TotalPowerEarned=createLabel("TotalPowerEarned","📈 Total Power Earned",Color3.fromRGB(255,255,255))
	local startTime=os.time()labels.Timer.Text="00:00:00"
	local function updateTimer()local elapsed=os.time()-startTime;local hours=math.floor(elapsed/3600);local minutes=math.floor((elapsed%3600)/60);local seconds=elapsed%60;labels.Timer.Text=string.format("%02d:%02d:%02d",hours,minutes,seconds)end
	local function setTrainingDividersColor(statName)local color=STAT_COLORS[statName];if color then labels.SepTop.BackgroundColor3=color;labels.SepBottom.BackgroundColor3=color;labels.SepTop.Visible=true;labels.SepBottom.Visible=true else labels.SepTop.Visible=false;labels.SepBottom.Visible=false end end
	local function getPotionBonus(index)local hud=playerGui:FindFirstChild("HUD");if not hud then return "" end local topUi=hud:FindFirstChild("TopUi");if not topUi then return "" end local rank=topUi:FindFirstChild("Rank");if not rank then return "" end local data=rank:FindFirstChild("Data");if not data then return "" end local potionEffect=data:FindFirstChild("PotionEffect");if not potionEffect then return "" end local slot=potionEffect:FindFirstChild(tostring(index));if not slot then return "" end local design=slot:FindFirstChild("Design");if not design then return "" end local bonus=design:FindFirstChild("Bonus");if not bonus then return "" end if bonus:IsA("ValueBase")then return tostring(bonus.Value or"")end if bonus:IsA("TextLabel")or bonus:IsA("TextBox")or bonus:IsA("TextButton")then return tostring(bonus.Text or"")end return "" end
	local initialTotalPower=getNumberValue(statsFolder,"TotalPower")
	local function updateBoosts()for i=1,6 do local bonusText=getPotionBonus(i);local lbl=boostLabels[i];if bonusText~=""then lbl.Text=string.format("%s %s",BOOST_EMOJIS[i],bonusText);lbl.Visible=true else lbl.Text="";lbl.Visible=false end end end
	local function updateStats()local s=statsFolder;local statTraining=getStringValue(s,"StatTraining");local rawTick=getNumberValue(s,"TrainingTick");local trainingTick=rawTick;if rawTick>=9e12 and rawTick<1e13 then trainingTick=rawTick*10 end;if statTraining==""then labels.Training.Text="📋 Training None";setTrainingDividersColor(nil)else labels.Training.Text=string.format("📋 Training %s +%s Per Tick",statTraining,formatNumber(trainingTick));setTrainingDividersColor(statTraining)end
		local power=getNumberValue(s,"Power");local health=getNumberValue(s,"Health");local defense=getNumberValue(s,"Defense");local psychics=getNumberValue(s,"Psychics");local magic=getNumberValue(s,"Magic");local mobility=getNumberValue(s,"Mobility");local totalPower=getNumberValue(s,"TotalPower");local tokens=getNumberValue(s,"Tokens")
		labels.Tokens.Text="💰 Tokens: "..formatNumber(tokens);labels.Power.Text="💪 Power: "..formatNumber(power);labels.Health.Text="❤️ Health: "..formatNumber(health);labels.Defense.Text="🛡️ Defense: "..formatNumber(defense);labels.Psychics.Text="🔮 Psychics: "..formatNumber(psychics);labels.Magic.Text="✨ Magic: "..formatNumber(magic);labels.Mobility.Text="💨 Mobility: "..formatNumber(mobility);labels.TotalPower.Text="📊 Total Power: "..formatNumber(totalPower)
		local earned=math.max(0,totalPower-(initialTotalPower or totalPower));labels.TotalPowerEarned.Text="📈 Total Power Earned: "..formatNumber(earned)
	end
	task.spawn(function()while task.wait(1) do updateTimer();updateStats();updateBoosts() end end)
	U.InputBegan:Connect(function(i,gp)if gp then return end if i.KeyCode==Enum.KeyCode.P then screenGui.Enabled=not screenGui.Enabled end end)
end

local BG=mk('Frame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},G)
local SD=mk('ImageLabel',{Size=UDim2.new(0,860,0,560),Position=UDim2.new(0.5,-430,0.5,-280),BackgroundTransparency=1,Image='rbxassetid://5107167611',ImageColor3=Color3.fromRGB(0,0,0),ImageTransparency=0.25,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(10,10,118,118)},BG)
local MF=mk('Frame',{Name='MainFrame',Size=UDim2.new(0,840,0,540),Position=UDim2.new(0.5,-420,0.5,-270),BackgroundColor3=Color3.fromRGB(22,22,28),BorderSizePixel=0},BG)
mk('UICorner',{CornerRadius=UDim.new(0,14)},MF)
local TB=mk('Frame',{Name='TitleBar',Size=UDim2.new(1,0,0,48),BackgroundColor3=Color3.fromRGB(28,28,36),BorderSizePixel=0},MF)
mk('UICorner',{CornerRadius=UDim.new(0,14)},TB)
mk('UIGradient',{Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(40,40,54)),ColorSequenceKeypoint.new(1,Color3.fromRGB(28,28,36))}},TB)
mk('TextLabel',{Name='Title',Size=UDim2.new(1,-100,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text='Nedu Loadstring',TextColor3=Color3.fromRGB(235,235,245),TextScaled=true,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},TB)
mk('Frame',{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=Color3.fromRGB(0,170,255),BorderSizePixel=0},TB)
local Tabs=mk('Frame',{Name='TabContainer',Size=UDim2.new(0,180,1,-58),Position=UDim2.new(0,12,0,54),BackgroundColor3=Color3.fromRGB(26,26,34),BorderSizePixel=0},MF)
mk('UICorner',{CornerRadius=UDim.new(0,10)},Tabs)
local CC=mk('Frame',{Name='ContentContainer',Size=UDim2.new(1,-208,1,-58),Position=UDim2.new(0,196,0,54),BackgroundColor3=Color3.fromRGB(18,18,24),BorderSizePixel=0},MF)
mk('UICorner',{CornerRadius=UDim.new(0,10)},CC)
mk('UIPadding',{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},CC)
local CS=mk('ScrollingFrame',{Name='ContentScroll',Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0,2,0,2),BackgroundTransparency=1,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0)},CC)
mk('UIListLayout',{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},CS)

local waitingKey,SetHideBtn=false,nil
U.InputBegan:Connect(function(i,gp)
	if gp then return end
	if waitingKey and i.UserInputType==Enum.UserInputType.Keyboard then cfg.HideGUIKey=i.KeyCode.Name;save();waitingKey=false;if SetHideBtn then SetHideBtn.Text="Set Hide Key ("..(cfg.HideGUIKey or'RightControl')..")"end;return end
	if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode.Name==(cfg.HideGUIKey or'RightControl') then G.Enabled=not G.Enabled end
end)

local function TabBtn(p,t,ic)
	local b=mk('TextButton',{Size=UDim2.new(1,-16,0,40),Position=UDim2.new(0,8,0,0),BackgroundColor3=Color3.fromRGB(30,30,40),Text=ic..'  '..t,TextColor3=Color3.fromRGB(210,210,220),TextScaled=true,Font=Enum.Font.Gotham,BorderSizePixel=0},p)
	mk('UICorner',{CornerRadius=UDim.new(0,8)},b)
	local a=mk('Frame',{Size=UDim2.new(0,3,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(0,170,255),Visible=false},b)
	return b,a
end
local function Tab(name,icon)
	local c=0;for _,x in ipairs(Tabs:GetChildren())do if x:IsA('TextButton')then c+=1 end end
	local b,a=TabBtn(Tabs,name,icon);b.Position=UDim2.new(0,8,0,c*46+8)
	local t=mk('Frame',{Name=name..'Content',Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},CS)
	mk('UIListLayout',{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},t);mk('UIPadding',{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)},t)
	b.MouseButton1Click:Connect(function()
		for _,ch in ipairs(CS:GetChildren())do if ch:IsA('Frame')and ch.Name:find('Content')then ch.Visible=false end end
		for _,bb in ipairs(Tabs:GetChildren())do if bb:IsA('TextButton')then bb.BackgroundColor3=Color3.fromRGB(30,30,40);bb.TextColor3=Color3.fromRGB(210,210,220);local aa=bb:FindFirstChildOfClass('Frame');if aa then aa.Visible=false end end end
		t.Visible=true;b.BackgroundColor3=Color3.fromRGB(45,45,60);b.TextColor3=Color3.fromRGB(240,240,250);a.Visible=true
	end)
	return t
end
local function Section(p,title)
	local s=mk('Frame',{Name=title..'Section',Size=UDim2.new(1,-8,0,0),BackgroundColor3=Color3.fromRGB(24,24,32),BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y},p)
	mk('UICorner',{CornerRadius=UDim.new(0,10)},s)
	mk('TextLabel',{Name='Title',Size=UDim2.new(1,-12,0,28),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,Text=title,TextColor3=Color3.fromRGB(235,235,245),TextScaled=true,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},s)
	local c=mk('Frame',{Name='Content',Size=UDim2.new(1,-24,0,0),Position=UDim2.new(0,12,0,44),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},s)
	mk('UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},c)
	return c
end
local function Toggle(p,name,key,cb)
	local r=mk('Frame',{Name=name..'Toggle',Size=UDim2.new(1,0,0,32),BackgroundTransparency=1},p)
	local bg=mk('Frame',{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(28,28,38),BorderSizePixel=0},r)
	mk('UICorner',{CornerRadius=UDim.new(0,8)},bg)
	mk('TextLabel',{Size=UDim2.new(1,-72,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=name,TextColor3=Color3.fromRGB(230,230,240),TextScaled=true,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},bg)
	local b=mk('TextButton',{Size=UDim2.new(0,52,0,24),Position=UDim2.new(1,-64,0.5,-12),BackgroundColor3=Color3.fromRGB(60,60,70),Text='',BorderSizePixel=0},bg)
	mk('UICorner',{CornerRadius=UDim.new(1,0)},b)
	local k=mk('Frame',{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,2,0.5,-10),BackgroundColor3=Color3.fromRGB(200,200,205),BorderSizePixel=0},b)
	mk('UICorner',{CornerRadius=UDim.new(1,0)},k)
	local function vis()local on=cfg[key];b.BackgroundColor3=on and Color3.fromRGB(0,170,255)or Color3.fromRGB(60,60,70);k:TweenPosition(on and UDim2.new(1,-22,0.5,-10)or UDim2.new(0,2,0.5,-10),'Out','Quad',0.15,true)end
	b.MouseButton1Click:Connect(function()cfg[key]=not cfg[key];vis();if cb then cb(cfg[key])end;save()end)
	vis();task.defer(function()if cb then cb(cfg[key])end end)
	return r
end
local function Slider(p,name,key,min,max,def,cb)
	local f=mk('Frame',{Name=name..'Slider',Size=UDim2.new(1,0,0,48),BackgroundTransparency=1},p)
	local bg=mk('Frame',{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(28,28,38),BorderSizePixel=0},f)
	mk('UICorner',{CornerRadius=UDim.new(0,8)},bg)
	local lbl=mk('TextLabel',{Size=UDim2.new(1,-12,0,20),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,Text=name..': '..(cfg[key]or def),TextColor3=Color3.fromRGB(230,230,240),TextScaled=true,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},bg)
	local bar=mk('Frame',{Size=UDim2.new(1,-24,0,6),Position=UDim2.new(0,12,1,-14),BackgroundColor3=Color3.fromRGB(55,55,65),BorderSizePixel=0},bg)
	mk('UICorner',{CornerRadius=UDim.new(0,3)},bar)
	local fill=mk('Frame',{Size=UDim2.new(0,0,1,0),BackgroundColor3=Color3.fromRGB(0,170,255),BorderSizePixel=0},bar);mk('UICorner',{CornerRadius=UDim.new(0,3)},fill)
	local knob=mk('Frame',{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,-7,0.5,-7),BackgroundColor3=Color3.fromRGB(235,235,245),BorderSizePixel=0},bar);mk('UICorner',{CornerRadius=UDim.new(1,0)},knob)
	local drag=false
	local function apply(v)local s=0.01;v=math.floor((v/s)+0.5)*s;v=math.clamp(v,min,max);local pct=(v-min)/(max-min);fill.Size=UDim2.new(pct,0,1,0);knob.Position=UDim2.new(pct,-7,0.5,-7);lbl.Text=name..': '..string.format('%.2f',v);cfg[key]=v;if cb then cb(v)end;save()end
	apply(cfg[key]or def)
	bar.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
	U.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
	U.InputChanged:Connect(function(i)if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local m=U:GetMouseLocation();local p=bar.AbsolutePosition;local s=bar.AbsoluteSize;local pct=math.clamp((m.X-p.X)/s.X,0,1);apply(min+(max-min)*pct)end end)
	return f
end
local function Btn(p,n,cb)local b=mk('TextButton',{Name=n..'Button',Size=UDim2.new(0,260,0,32),BackgroundColor3=Color3.fromRGB(36,36,48),BorderSizePixel=0,Text=n,TextColor3=Color3.fromRGB(235,235,245),TextScaled=true,Font=Enum.Font.Gotham},p)mk('UICorner',{CornerRadius=UDim.new(0,8)},b)b.MouseButton1Click:Connect(function()if cb then pcall(cb)end end)return b end
local function title(p,t)mk('TextLabel',{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text=t,TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},p)end

local drag,dragIn,dragStart,startPos
local function upd(i)local d=i.Position-dragStart;MF.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y);SD.Position=UDim2.new(0,MF.Position.X.Offset-10,0,MF.Position.Y.Offset-10)end
TB.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;dragStart=i.Position;startPos=MF.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then drag=false end end)end end)
TB.InputChanged:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseMovement then dragIn=i end end)
U.InputChanged:Connect(function(i)if i==dragIn and drag then upd(i)end end)

local Combat=Tab('Combat','⚔️');local Move=Tab('Movement','🏃');local Util=Tab('Utility','🔧');local Visual=Tab('Visual','👁️');local Quests=Tab('Quests','📋');local Shops=Tab('Shops','🛒');local Tele=Tab('Teleport','🧭');local HealthT=Tab('Health','❤️');local Potions=Tab('Potions','🧪');local Conf=Tab('Config','⚙️')

local CScroll=mk('ScrollingFrame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0)},Combat)
local CLayout=mk('UIListLayout',{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},CScroll)
CLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()CScroll.CanvasSize=UDim2.new(0,0,0,CLayout.AbsoluteContentSize.Y+12)end)
local UScroll=mk('ScrollingFrame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0)},Util)
local ULayout=mk('UIListLayout',{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},UScroll)
ULayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()UScroll.CanvasSize=UDim2.new(0,0,0,ULayout.AbsoluteContentSize.Y+12)end)
local TR=mk('Frame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},Tele)
local LC=mk('ScrollingFrame',{Name='LeftCol',Size=UDim2.new(0.55,-8,1,0),BackgroundTransparency=1,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0)},TR)
local LL=mk('UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},LC)
LL:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()LC.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+20)end)
local RC=mk('ScrollingFrame',{Name='RightCol',Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.55,8,0,0),BackgroundTransparency=1,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0)},TR)
local RL=mk('UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},RC)
RL:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()RC.CanvasSize=UDim2.new(0,0,0,RL.AbsoluteContentSize.Y+20)end)

local function instAt(parts)local cur=workspace;for _,n in ipairs(parts)do if not cur or not cur.FindFirstChild then return nil end;cur=cur:FindFirstChild(n)end;return cur end
local function tpTo(t)local c,_,hrp=charHum();if not(c and hrp and t)then return end;local cf=t:IsA('BasePart')and t.CFrame or(t:IsA('Model')and t:GetPivot()or nil);if not cf then return end;local d=CFrame.new(cf.Position+cf.LookVector*4+Vector3.new(0,3,0),cf.Position+cf.LookVector*5);c:PivotTo(d)end
local function addTp(p,parts,label)Btn(p,label,function()local i=instAt(parts);if i then tpTo(i)end end)end

title(RC,'Players')
local PL=mk('Frame',{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},RC)
local PLL=mk('UIListLayout',{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},PL)
PLL:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()PL.Size=UDim2.new(1,0,0,PLL.AbsoluteContentSize.Y)end)
local pbtn={}
local function mkPB(plr)return Btn(PL,plr.Name,function()local c=plr.Character;local hrp=c and c:FindFirstChild('HumanoidRootPart');if hrp then local cf=CFrame.new(hrp.Position+Vector3.new(0,3,0),hrp.Position+hrp.CFrame.LookVector*2);local mc=LP.Character;if mc then pcall(function()mc:PivotTo(cf)end)end end end)end
local function refresh()for pl,b in pairs(pbtn)do pcall(function()b:Destroy()end);pbtn[pl]=nil end;for _,pl in ipairs(P:GetPlayers())do if pl~=LP then pbtn[pl]=mkPB(pl)end end end
refresh()
P.PlayerAdded:Connect(function(pl)if pl~=LP then pbtn[pl]=mkPB(pl)end end)
P.PlayerRemoving:Connect(function(pl)if pbtn[pl]then pcall(function()pbtn[pl]:Destroy()end);pbtn[pl]=nil end end)
title(RC,'Saved Position')
local row=mk('Frame',{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},RC)
local rowL=mk('UIListLayout',{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},row)
Btn(row,'Save Place',function()
	local c,_,hrp=charHum();if hrp then
		local cf=hrp.CFrame
		_G.__SavedCFrame=cf
		savedCFrame=cf
		persistSave(cf)
	end
end)
Btn(row,'Teleport To Save',function()
	local cf=_G.__SavedCFrame or savedCFrame
	if not cf then loadPersistedSave(); cf=savedCFrame end
	local c=LP.Character;if cf and c then pcall(function()c:PivotTo(cf)end)end
end)
rowL:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()row.Size=UDim2.new(1,0,0,rowL.AbsoluteContentSize.Y)end)

-- Zones (RIGHT COLUMN)
title(RC,'Zones')

-- Defense zones resolvers
local function resolveHeavensDoorPart()local ok,res=pcall(function()local hd=workspace:FindFirstChild("HeavensDoor")return hd and hd:GetChildren()[10] or nil end)return ok and res or nil end
local function resolveUndergroundQDoorPart()local ok,res=pcall(function()local gm=workspace:FindFirstChild("GameMap");local ug=gm and gm:FindFirstChild("Underground");local c=ug and ug:FindFirstChild("R237G234B234");local qd=c and c:FindFirstChild("? Door");local mdl=qd and qd:FindFirstChild("Model")return mdl and mdl:GetChildren()[2] or nil end)return ok and res or nil end
local function resolveIceCrystalPart()local ok,res=pcall(function()local child=workspace:GetChildren()[95];local ic=child and child:FindFirstChild("Ice Crystal")return ic and ic:GetChildren()[2] or nil end)return ok and res or nil end
local function resolveCatacombsCityPart()local ok,res=pcall(function()local city=workspace:FindFirstChild("CatacombsCity")return city and city:GetChildren()[3074] or nil end)return ok and res or nil end
local function resolveHellMapUnion()local ok,res=pcall(function()local hm=workspace:FindFirstChild("HellMap")return hm and hm:FindFirstChild("Union") or nil end)return ok and res or nil end

-- Power zones resolvers
local function resolveFireCrystalPart()local ok,res=pcall(function()local child=workspace:GetChildren()[117];local child7=child and child:GetChildren()[7];local mdl=child7 and child7:FindFirstChild("Model");local mdl2=mdl and mdl:FindFirstChild("Model");local fc=mdl2 and mdl2:FindFirstChild("Fire Crystal")return fc and fc:GetChildren()[2] or nil end)return ok and res or nil end
local function resolvePower30()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local pwr=ti and ti:FindFirstChild("Power")return pwr and pwr:FindFirstChild("30") or nil end)return ok and res or nil end
local function resolveHellMapPower()local ok,res=pcall(function()local hm=workspace:FindFirstChild("HellMap")return hm and hm:GetChildren()[2729] or nil end)return ok and res or nil end
local function resolvePower28()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local pwr=ti and ti:FindFirstChild("Power")return pwr and pwr:FindFirstChild("28") or nil end)return ok and res or nil end
local function resolveMeteoriteOrb()local ok,res=pcall(function()local meteorite=workspace:FindFirstChild("meteorite for psl")return meteorite and meteorite:FindFirstChild("orb") or nil end)return ok and res or nil end

-- Magic zones resolvers
local function resolveMagicPart()local ok,res=pcall(function()local child=workspace:GetChildren()[136]return child and child:FindFirstChild("Part") or nil end)return ok and res or nil end
local function resolveMagic15()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("15") or nil end)return ok and res or nil end
local function resolveMagic14()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("14") or nil end)return ok and res or nil end
local function resolveMagic13()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("13") or nil end)return ok and res or nil end
local function resolveMagic12()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("12") or nil end)return ok and res or nil end

-- Psychic zones resolvers
local function resolvePsychicTree()local ok,res=pcall(function()local gm=workspace:FindFirstChild("GameMap");local ug=gm and gm:FindFirstChild("Underground");local c=ug and ug:FindFirstChild("R237G234B234");local child5=c and c:GetChildren()[5];local mdl=child5 and child5:FindFirstChild("Model");local tree=mdl and mdl:FindFirstChild("Tree3")return tree and tree:FindFirstChild("Trunk") or nil end)return ok and res or nil end
local function resolvePsychic28()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("28") or nil end)return ok and res or nil end
local function resolvePsychic27()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("27") or nil end)return ok and res or nil end
local function resolvePsychic24()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("24") or nil end)return ok and res or nil end
local function resolvePsychic23()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("23") or nil end)return ok and res or nil end
local function resolvePsychic22()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("22") or nil end)return ok and res or nil end

-- Best area teleports
local function bestDefenseTeleport()local statsFolder=RS:WaitForChild("Data"):WaitForChild(LP.Name):WaitForChild("Stats");local v=statsFolder and statsFolder:FindFirstChild("Defense") and statsFolder.Defense.Value or 0
	local zones={{req=1e20,getter=resolveHeavensDoorPart},{req=1e19,getter=resolveUndergroundQDoorPart},{req=1e18,getter=resolveIceCrystalPart},{req=1e17,getter=resolveCatacombsCityPart},{req=1e16,getter=resolveHellMapUnion}}
	for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpTo(inst) return end end end
end
local function bestPowerTeleport()local statsFolder=RS:WaitForChild("Data"):WaitForChild(LP.Name):WaitForChild("Stats");local v=statsFolder and statsFolder:FindFirstChild("Power") and statsFolder.Power.Value or 0
	local zones={{req=1e20,getter=resolveFireCrystalPart},{req=1e19,getter=resolvePower30},{req=1e18,getter=resolveHellMapPower},{req=1e17,getter=resolvePower28},{req=1e16,getter=resolveMeteoriteOrb}}
	for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpTo(inst) return end end end
end
local function bestMagicTeleport()local statsFolder=RS:WaitForChild("Data"):WaitForChild(LP.Name):WaitForChild("Stats");local v=statsFolder and statsFolder:FindFirstChild("Magic") and statsFolder.Magic.Value or 0
	local zones={{req=1e20,getter=resolveMagicPart},{req=1e19,getter=resolveMagic15},{req=1e18,getter=resolveMagic14},{req=1e17,getter=resolveMagic13},{req=5e15,getter=resolveMagic12}}
	for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpTo(inst) return end end end
end
local function bestPsychicTeleport()local statsFolder=RS:WaitForChild("Data"):WaitForChild(LP.Name):WaitForChild("Stats");local v=statsFolder and statsFolder:FindFirstChild("Psychics") and statsFolder.Psychics.Value or 0
	local zones={{req=1e20,getter=resolvePsychicTree},{req=1e19,getter=resolvePsychic28},{req=1e18,getter=resolvePsychic27},{req=1e17,getter=resolvePsychic24},{req=5e16,getter=resolvePsychic23},{req=5e15,getter=resolvePsychic22}}
	for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpTo(inst) return end end end
end

Btn(RC,'Defense',function()pcall(bestDefenseTeleport)end)
Btn(RC,'Power',function()pcall(bestPowerTeleport)end)
Btn(RC,'Magic',function()pcall(bestMagicTeleport)end)
Btn(RC,'Psychic',function()pcall(bestPsychicTeleport)end)

title(LC,'Exotics')
addTp(LC,{'Pads','ExoticStore','1'},'Exotic Store')
addTp(LC,{'Pads','ExoticStore2','1'},'Dark Exotic Store')

title(LC,'Stores')
addTp(LC,{'Pads','Store','1'},'Starter Store')
addTp(LC,{'Pads','Store','9'},'Tower Store')

title(LC,'Tools')
addTp(LC,{'Pads','Store','2'},'Supermarket')

title(LC,'Talismans')
addTp(LC,{'Pads','Store','3'},'Gym Store')

title(LC,'Necklaces')
addTp(LC,{'Pads','Store','4'},'Necklace Store')

title(LC,'Weapons')
addTp(LC,{'Pads','Store','5'},'Melee Store')

title(LC,'Avatars')
addTp(LC,{'Pads','Store','12'},'Accessory Store')
addTp(LC,{'Pads','Store','13'},'Fighter Helmets')
addTp(LC,{'Pads','Store','10'},'Luxury Hats Store')

title(LC,'Auras')
addTp(LC,{'Pads','Store','11'},'Basic Trails Store')
addTp(LC,{'Pads','Store','14'},'Advanced Trails')
addTp(LC,{'Pads','Store','15'},'Legendary Trails')

title(LC,'Transforms')
addTp(LC,{'Pads','Store','6'},'Premium Shop')
addTp(LC,{'Pads','Store','7'},'Armour Shop 1')
addTp(LC,{'Pads','Store','8'},'Armour Shop 2')
addTp(LC,{'Pads','DeluxoUpgrade','Credits'},'Deluxo Upgrade')

title(LC,'Wands')
addTp(LC,{'Pads','Wands','1'},'Wand Store 1')
addTp(LC,{'Pads','Wands','2'},'Wand Store 2')

title(LC,'Weights')
for i=1,5 do addTp(LC,{'Pads','Weight',tostring(i)},'Weight Store '..i)end

title(LC,'Questlines')
addTp(LC,{'Pads','MainTasks','MainTask'},'Main Task')
addTp(LC,{'Pads','MainTasks','AQuest'},'Aquest')
addTp(LC,{'Pads','MainTasks','LucaTask'},'Luca Task')
addTp(LC,{'Pads','MainTasks','TowerFacility'},'Tower Facility')
addTp(LC,{'Pads','MainTasks','ReaperTask'},'Reaper Tasks')
addTp(LC,{'Pads','MainTasks','GladiatorTask'},'Gladiator Task')
addTp(LC,{'Pads','MainTasks','AncientQuests'},'Ancient Quests')
addTp(LC,{'Pads','MainTasks','TankQuests'},'Tank')
addTp(LC,{'Pads','MainTasks','PowerQuests'},'Fighter')
addTp(LC,{'Pads','MainTasks','MagicQuests'},'Wizard')
addTp(LC,{'Pads','MainTasks','MobilityQuests'},'Speedstar')

title(LC,'Side Tasks')
addTp(LC,{'Pads','SideTasks','1'},'House Tasks')
addTp(LC,{'Pads','SideTasks','2'},'Hunter')
addTp(LC,{'Pads','SideTasks','3'},'Commander')
addTp(LC,{'Pads','SideTasks','4'},'Wizard')
addTp(LC,{'Pads','SideTasks','7'},'Arena Investor')

title(LC,'Experiments')
addTp(LC,{'Experiment','FloorHitbox'},'Floor')
addTp(LC,{'Experiment','SurvivalHitbox'},'Survival')
addTp(LC,{'Pads','Telekinesis','Telekinesis'},'Telekinesis')
addTp(LC,{'WallGame','WallHitbox'},'Wall')
addTp(LC,{'Experiment','Energy','15','Part'},'Energy')

local NC={conn=nil,char=nil,desc=nil,orig={}}
local function ncRec(p)if not NC.orig[p]then NC.orig[p]=p.CanCollide end end
local function ncPart(p)if p:IsA('BasePart')then ncRec(p);p.CanCollide=false end end
local function ncAll()local c=LP.Character;if not c then return end;for _,p in ipairs(c:GetDescendants())do ncPart(p)end end
local function ncRestore()for p,w in pairs(NC.orig)do if p and p.Parent then pcall(function()p.CanCollide=w end)end end;table.clear(NC.orig)end
local function TNoClip(on)
	getgenv().NoClip=on
	if on then
		if NC.conn then NC.conn:Disconnect()end;if NC.char then NC.char:Disconnect()end;if NC.desc then NC.desc:Disconnect()end
		ncAll();NC.conn=R.Stepped:Connect(function()if getgenv().NoClip then ncAll()end end)
		NC.char=LP.CharacterAdded:Connect(function(c)if getgenv().NoClip then table.clear(NC.orig);task.wait(0.1);ncAll();if NC.desc then NC.desc:Disconnect()end;NC.desc=c.DescendantAdded:Connect(function(i)if getgenv().NoClip then ncPart(i)end end)end end)
		local c=LP.Character;if c then if NC.desc then NC.desc:Disconnect()end;NC.desc=c.DescendantAdded:Connect(function(i)if getgenv().NoClip then ncPart(i)end end)end
	else
		if NC.conn then NC.conn:Disconnect()NC.conn=nil end;if NC.char then NC.char:Disconnect()NC.char=nil end;if NC.desc then NC.desc:Disconnect()NC.desc=nil end;ncRestore()
	end
end

local function TAFK(on)getgenv().GraphicsOptimization=on;pcall(function()settings().Rendering.QualityLevel=on and 1 or 21;settings().Physics.PhysicsSendRate=on and 1 or 60 end)end

local Adv={lighting={},terrain={},conns={}}
local function TGfxAdv(on)
	getgenv().GraphicsOptimizationAdvanced=on
	local Ter=workspace:FindFirstChildOfClass('Terrain')
	local function set(b,i,p,v)if Adv[b][i]==nil then Adv[b][i]={}end;if Adv[b][i][p]==nil then local ok,old=pcall(function()return i[p]end);if ok then Adv[b][i][p]=old end end;pcall(function()i[p]=v end)end
	local function restore()for t,insts in pairs(Adv)do if t~='conns'then for i,props in pairs(insts)do for pr,ov in pairs(props)do pcall(function()i[pr]=ov end)end end Adv[t]={}end end;for _,c in ipairs(Adv.conns)do pcall(function()c:Disconnect()end)end Adv.conns={} end
	if not on then restore();return end
	set('lighting',L,'Brightness',2);set('lighting',L,'ClockTime',14);set('lighting',L,'GlobalShadows',false);set('lighting',L,'ShadowSoftness',0);set('lighting',L,'EnvironmentDiffuseScale',0);set('lighting',L,'EnvironmentSpecularScale',0)
	for _,o in ipairs(L:GetChildren())do local c=o.ClassName
		if c=='BloomEffect'or c=='DepthOfFieldEffect'or c=='ColorCorrectionEffect'or c=='SunRaysEffect'or c=='BlurEffect'then set('lighting',o,'Enabled',false)
		elseif c=='Atmosphere'then set('lighting',o,'Density',0);set('lighting',o,'Haze',0);set('lighting',o,'Glare',0)
		elseif c=='Clouds'then set('lighting',o,'Coverage',0);set('lighting',o,'Density',0)end
	end
	if Ter then set('terrain',Ter,'Decoration',false);set('terrain',Ter,'WaterReflectance',0);set('terrain',Ter,'WaterTransparency',1);set('terrain',Ter,'WaterWaveSize',0);set('terrain',Ter,'WaterWaveSpeed',0)end
	local function simple(i)local c=i.ClassName
		if c=='ParticleEmitter'or c=='Trail'or c=='Beam'or c=='Smoke'or c=='Fire'or c=='Sparkles'then pcall(function()i.Enabled=false end)
		elseif c=='PointLight'or c=='SpotLight'or c=='SurfaceLight'then if i.Enabled~=nil then pcall(function()i.Enabled=false end)else pcall(function()i.Brightness=0 end)end
		elseif c=='Decal'or c=='Texture'then pcall(function()i.Transparency=1 end)
		elseif c=='MeshPart'then pcall(function()i.RenderFidelity=Enum.RenderFidelity.Performance end)end
	end
	for _,d in ipairs(workspace:GetDescendants())do simple(d)end
	table.insert(Adv.conns,workspace.DescendantAdded:Connect(simple))
end

local UOpt={applied=false,changed={},conn=nil}
local function TUltimate(on)cfg.UltimateAFKOptimization=on;save()
	local S=UOpt
	local function rest()for i=#S.changed,1,-1 do local r=S.changed[i];if r.inst and r.inst.Parent~=nil then pcall(function()r.inst[r.prop]=r.old end)end S.changed[i]=nil end;if S.conn then pcall(function()S.conn:Disconnect()end)S.conn=nil end;S.applied=false end
	if not on then rest();pcall(function()settings().Rendering.QualityLevel=21;settings().Physics.PhysicsSendRate=60 end);return end
	if S.applied then return end
	local function set(i,p,v)pcall(function()local ok,old=pcall(function()return i[p]end);if ok then table.insert(S.changed,{inst=i,prop=p,old=old})end;i[p]=v end)end
	pcall(function()settings().Rendering.QualityLevel=1;settings().Physics.PhysicsSendRate=1 end)
	set(L,'Brightness',2);set(L,'ClockTime',14);set(L,'GlobalShadows',false);set(L,'ShadowSoftness',0);set(L,'EnvironmentDiffuseScale',0);set(L,'EnvironmentSpecularScale',0)
	for _,o in ipairs(L:GetChildren())do local c=o.ClassName;if c=='BloomEffect'or c=='DepthOfFieldEffect'or c=='ColorCorrectionEffect'or c=='SunRaysEffect'or c=='BlurEffect'then set(o,'Enabled',false)
		elseif c=='Atmosphere'then set(o,'Density',0);set(o,'Haze',0);set(o,'Glare',0)
		elseif c=='Clouds'then set(o,'Coverage',0);set(o,'Density',0)end end
	local t=workspace:FindFirstChildOfClass('Terrain');if t then set(t,'Decoration',false);set(t,'WaterReflectance',0);set(t,'WaterTransparency',1);set(t,'WaterWaveSize',0);set(t,'WaterWaveSpeed',0)end
	local function simple(i)local c=i.ClassName
		if c=='ParticleEmitter'or c=='Trail'or c=='Beam'or c=='Smoke'or c=='Fire'or c=='Sparkles'then if pcall(function()return i.Enabled end)then set(i,'Enabled',false)end
		elseif c=='PointLight'or c=='SpotLight'or c=='SurfaceLight'then if pcall(function()return i.Enabled end)then set(i,'Enabled',false)else set(i,'Brightness',0)end
		elseif c=='Decal'or c=='Texture'then set(i,'Transparency',1)
		elseif c=='MeshPart'then set(i,'RenderFidelity',Enum.RenderFidelity.Performance)end
	end
	for _,d in ipairs(workspace:GetDescendants())do simple(d)end
	S.conn=workspace.DescendantAdded:Connect(simple);S.applied=true
end

-- Mob name mapping for selection
local BUCKET_NAME = {
	["1"]="Goblin",["2"]="Thug",["3"]="Gym Rat",["4"]="Veteran",["5"]="Yakuza",
	["6"]="Mutant",["7"]="Samurai",["8"]="Ninja",["9"]="Animatronic",
	["10"]="Catacombs Guard",["11"]="Catacombs Guard",["12"]="Catacombs Guard",
	["13"]="Demon",["14"]="The Judger",["15"]="Dominator",["16"]="Arena",["17"]="The Emperor",
	["18"]="Ancient Gladiator",["19"]="Old Knight",
}
local function bucketOf(inst)local root=workspace:FindFirstChild("Enemies");if not root then return nil end;local node=inst
	while node and node~=root do if node.Parent==root and tonumber(node.Name)~=nil then return node end node=node.Parent end
	return nil end
local function getMobDisplayName(model)
	local b=bucketOf(model);local id=b and b.Name or nil
	if id and BUCKET_NAME[id] and BUCKET_NAME[id]~="" then return BUCKET_NAME[id] end
	local hum=model:FindFirstChildOfClass("Humanoid")
	if hum and hum.DisplayName and hum.DisplayName~="" then return hum.DisplayName end
	for _,a in ipairs({"EnemyName","DisplayName","NameOverride","MobType","Type"}) do local v=model:GetAttribute(a);if v and tostring(v)~="" then return tostring(v) end end
	return model.Name
end
local function uniqueMobNames()local seen, list = {}, {}
	for _,name in pairs(BUCKET_NAME) do if name and name~="" and not seen[name] then seen[name]=true;table.insert(list,name) end end
	table.sort(list);return list
end
local function isMobSelected(name)return cfg.UFAOrderedMobs and table.find(cfg.UFAOrderedMobs, name) ~= nil end

-- Player ESP (old visuals) with robust cleanup to prevent stuck overlays
local function TPlayerESP(on)
	cfg.PlayerESP = on
	if not Drawing then return end

	getgenv().__PESP = getgenv().__PESP or {conn=nil, wd=nil, records={}}
	local S = getgenv().__PESP

	local function rm(rec)
		if not rec then return end
		pcall(function() if rec.b then rec.b:Remove() end end)
		pcall(function() if rec.t then rec.t:Remove() end end)
		pcall(function() if rec.clan then rec.clan:Remove() end end)
		pcall(function() if rec.health then rec.health:Remove() end end)
		pcall(function() if rec.defense then rec.defense:Remove() end end)
		pcall(function() if rec.power then rec.power:Remove() end end)
		pcall(function() if rec.magic then rec.magic:Remove() end end)
		pcall(function() if rec.rep then rec.rep:Remove() end end)
	end
	local function clearAll()
		if S.conn then pcall(function() S.conn:Disconnect() end) S.conn=nil end
		if S.wd then pcall(function() S.wd:Disconnect() end) S.wd=nil end
		for k,rec in pairs(S.records) do rm(rec) S.records[k]=nil end
	end

	if not on then
		clearAll()
		return
	end

	-- re-enable: hard clear any leftovers first
	clearAll()

	local function formatNumber(num)
		local absNum = math.abs(num)
		if absNum == 0 then return "Concealed"
		elseif absNum >= 1e18 then return string.format("%.2fQn", num/1e18)
		elseif absNum >= 1e15 then return string.format("%.2fQd", num/1e15)
		elseif absNum >= 1e12 then return string.format("%.2fT",  num/1e12)
		elseif absNum >= 1e9  then return string.format("%.2fB",  num/1e9)
		elseif absNum >= 1e6  then return string.format("%.2fM",  num/1e6)
		elseif absNum >= 1e3  then return string.format("%.2fK",  num/1e3)
		else return tostring(num) end
	end

	local function getPlayerStats(player)
		local ok, statsFolder = pcall(function() return RS.Data[player.Name].Stats end)
		if ok and statsFolder then
			local d = statsFolder:FindFirstChild('Defense')
			local p = statsFolder:FindFirstChild('Power')
			local m = statsFolder:FindFirstChild('Magic')
			local r = statsFolder:FindFirstChild('Reputation')
			return d and d.Value or 0, p and p.Value or 0, m and m.Value or 0, r and r.Value or 0
		end
		return 0,0,0,0
	end

	local function getPlayerClan(player)
		local ok, statsFolder = pcall(function() return RS.Data[player.Name].Stats end)
		if ok and statsFolder then
			local clanJoined = statsFolder:FindFirstChild('ClanJoined')
			if clanJoined then
				local clanId = clanJoined.Value
				local clanNames = {[6440]="Calamity2",[7]="Calamity",[11]="YTPvP",[3704]="YTPvP2",[4588]="YTpvP3"}
				local clanColors = {[6440]=Color3.fromRGB(0,255,0),[7]=Color3.fromRGB(0,255,0),[11]=Color3.fromRGB(255,0,0),[3704]=Color3.fromRGB(255,0,0),[4588]=Color3.fromRGB(255,0,0)}
				return clanNames[clanId], clanColors[clanId]
			end
		end
		return nil,nil
	end

	local function getPlayerHealth(player)
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then return humanoid.Health, humanoid.MaxHealth end
		return 0,0
	end

	local function getRepColor(v)
		if v<=-25000 then return Color3.fromRGB(0,0,0)
		elseif v<=-10000 then return Color3.fromRGB(139,0,0)
		elseif v<=-4000 then return Color3.fromRGB(128,0,128)
		elseif v<=-1 then return Color3.fromRGB(255,100,100)
		elseif v==0 then return Color3.fromRGB(255,255,255)
		elseif v<4000 then return Color3.fromRGB(0,255,0)
		elseif v<10000 then return Color3.fromRGB(64,224,208)
		elseif v<25000 then return Color3.fromRGB(173,216,230)
		else return Color3.fromRGB(255,255,0) end
	end

	local function mkRec()
		local b = Drawing.new('Square'); b.Filled=false; b.Thickness=2; b.Visible=false
		local t = Drawing.new('Text'); t.Size=20; t.Center=true; t.Outline=true; t.OutlineColor=Color3.new(0,0,0); t.Visible=false
		local clan = Drawing.new('Text'); clan.Size=16; clan.Center=true; clan.Outline=true; clan.OutlineColor=Color3.new(0,0,0); clan.Visible=false
		local health = Drawing.new('Text'); health.Size=16; health.Center=true; health.Outline=true; health.OutlineColor=Color3.new(0,0,0); health.Color=Color3.fromRGB(100,255,100); health.Visible=false
		local defense = Drawing.new('Text'); defense.Size=16; defense.Center=true; defense.Outline=true; defense.OutlineColor=Color3.new(0,0,0); defense.Color=Color3.fromRGB(0,150,255); defense.Visible=false
		local power = Drawing.new('Text'); power.Size=16; power.Center=true; power.Outline=true; power.OutlineColor=Color3.new(0,0,0); power.Color=Color3.fromRGB(255,50,50); power.Visible=false
		local magic = Drawing.new('Text'); magic.Size=16; magic.Center=true; magic.Outline=true; magic.OutlineColor=Color3.new(0,0,0); magic.Color=Color3.fromRGB(255,100,255); magic.Visible=false
		local rep = Drawing.new('Text'); rep.Size=16; rep.Center=true; rep.Outline=true; rep.OutlineColor=Color3.new(0,0,0); rep.Color=Color3.fromRGB(255,255,255); rep.Visible=false
		return {b=b,t=t,clan=clan,health=health,defense=defense,power=power,magic=magic,rep=rep}
	end

	local function ensure(plr)
		if S.records[plr] then return S.records[plr] end
		local rec = mkRec()
		S.records[plr] = rec
		return rec
	end

	-- Clean on player remove
	if not S._pr then
		S._pr = P.PlayerRemoving:Connect(function(plr)
			local rec = S.records[plr]
			if rec then rm(rec) S.records[plr]=nil end
		end)
	end

	-- Watchdog to purge orphans each step
	S.wd = R.Stepped:Connect(function()
		for plr,rec in pairs(S.records) do
			if typeof(plr) ~= "Instance" or not plr:IsDescendantOf(game) then
				rm(rec) S.records[plr]=nil
			end
		end
	end)

	S.conn = R.RenderStepped:Connect(function()
		if not cfg.PlayerESP then
			clearAll()
			return
		end

		for _,pl in ipairs(P:GetPlayers()) do
			if pl ~= LP then
				local char = pl.Character
					local HumanoidRootPart = char and char:FindFirstChild('HumanoidRootPart')
					local Humanoid = char and char:FindFirstChildOfClass('Humanoid')
				local rec = ensure(pl)
					if HumanoidRootPart and Humanoid and Humanoid.Health > 0 then
						local Position, OnScreen = Cam:WorldToViewportPoint(HumanoidRootPart.Position)
						if OnScreen then
							-- Working scaling system from esph.lua
							local scale = 1 / (Position.Z * math.tan(math.rad(Cam.FieldOfView * 0.5)) * 2) * 1000
							local width, height = math.floor(4.5 * scale), math.floor(6 * scale)
							local x, y = math.floor(Position.X), math.floor(Position.Y)
							local xPosition, yPosition = math.floor(x - width * 0.5), math.floor((y - height * 0.5) + (0.5 * scale))
							
							-- Update box
							rec.b.Size = Vector2.new(width, height)
							rec.b.Position = Vector2.new(xPosition, yPosition)
						rec.b.Visible = true

						local clanName, clanColor = getPlayerClan(pl)
						rec.t.Text = pl.Name
						rec.t.Position = Vector2.new(x, yPosition - 25)
						rec.t.Visible = true

						if clanName then
							rec.clan.Text = clanName
							rec.clan.Position = Vector2.new(x, yPosition - 45)
							rec.clan.Color = clanColor
							rec.clan.Visible = true
						else
							rec.clan.Visible = false
						end

						local ch, mh = getPlayerHealth(pl)
						local defv, powv, magv, repv = getPlayerStats(pl)
						local combined = defv + magv + powv
						local low = combined < 1e17

						if low then
							rec.health.Visible=false; rec.defense.Visible=false; rec.power.Visible=false; rec.magic.Visible=false
							rec.rep.Text =(repv==0) and "0" or formatNumber(repv)
							rec.rep.Color = getRepColor(repv)
							rec.rep.Position = Vector2.new(x, yPosition + height + 16)
							rec.rep.Visible = true
						else
							rec.health.Text = formatNumber(ch).."/"..formatNumber(mh)
							rec.health.Position = Vector2.new(x, yPosition + height + 16)
							rec.health.Visible = true

							rec.defense.Text = formatNumber(defv)
							rec.defense.Position = Vector2.new(x, yPosition + height + 38)
							rec.defense.Visible = true

							rec.power.Text = formatNumber(powv)
							rec.power.Position = Vector2.new(x, yPosition + height + 60)
							rec.power.Visible = true

							rec.magic.Text = formatNumber(magv)
							rec.magic.Position = Vector2.new(x, yPosition + height + 82)
							rec.magic.Visible = true

							rec.rep.Text =(repv==0) and "0" or formatNumber(repv)
							rec.rep.Color = getRepColor(repv)
							rec.rep.Position = Vector2.new(x, yPosition + height + 104)
							rec.rep.Visible = true
						end
					else
						rec.b.Visible=false; rec.t.Visible=false; rec.clan.Visible=false
						rec.health.Visible=false; rec.defense.Visible=false; rec.power.Visible=false; rec.magic.Visible=false; rec.rep.Visible=false
					end
				else
					rec.b.Visible=false; rec.t.Visible=false; rec.clan.Visible=false
					rec.health.Visible=false; rec.defense.Visible=false; rec.power.Visible=false; rec.magic.Visible=false; rec.rep.Visible=false
				end
			end
		end
	end)
end

LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	TPlayerESP(cfg.PlayerESP)
end)

-- Full Mob ESP (boxes + names; smaller visuals; uses BUCKET_NAME/getMobDisplayName)
local function TMobESP(on)
	getgenv().EnemyESP2 = getgenv().EnemyESP2 or {enabled=false,_conns={},_records={}}
	local M = getgenv().EnemyESP2

	local function clearRecord(rec)
		if not rec then return end
		for _, c in ipairs(rec.conns or {}) do pcall(function() c:Disconnect() end) end
		if rec.box then pcall(function() rec.box:Destroy() end) end
		if rec.bill then pcall(function() rec.bill:Destroy() end) end
	end
	local function disableAll()
		for _, rec in pairs(M._records or {}) do clearRecord(rec) end
		if M.HOLDER then pcall(function() M.HOLDER:Destroy() end) end
		for _, c in ipairs(M._conns or {}) do pcall(function() c:Disconnect() end) end
		M._records, M._conns, M.enabled = {}, {}, false
	end
	if not on then if M.enabled then disableAll() end return end
	if M.enabled then return end
	M.enabled, M._conns, M._records = true, {}, {}

	local function ensureHolder()
		if M.HOLDER and M.HOLDER.Parent then return end
		local h = Instance.new("Folder")
		h.Name = "EnemyESP2_Holder"
		pcall(function() h.Parent = game:GetService("CoreGui") end)
		if not h.Parent then h.Parent = LP:WaitForChild("PlayerGui") end
		M.HOLDER = h
	end
	ensureHolder()

	local function enemiesRoot() return workspace:FindFirstChild("Enemies") end

	local CATACOMBS_IDS = { ["10"]=true, ["11"]=true, ["12"]=true }
	local CATACOMBS_COLOR = Color3.fromRGB(0,255,140)
	local function colorForBucketName(id)
		id = tostring(id or "")
		if CATACOMBS_IDS[id] then return CATACOMBS_COLOR end
		local n = tonumber(id) or 0
		return Color3.fromHSV((n % 12)/12, 0.85, 1)
	end

	local WEAPON_HINTS = {"weapon","sword","blade","gun","bow","staff","club","knife","axe","mace","spear"}
	local function looksLikeWeapon(name)
		name = string.lower(tostring(name or ""))
		for _, w in ipairs(WEAPON_HINTS) do if string.find(name, w, 1, true) then return true end end
		return false
	end
	local function isAccessoryPart(p)
		while p and p.Parent do if p:IsA("Accessory") then return true end p = p.Parent end
		return false
	end
	local function pickBodyPart(model)
		for _, n in ipairs({"HumanoidRootPart","UpperTorso","LowerTorso","Torso","Head"}) do
			local p = model:FindFirstChild(n)
			if p and p:IsA("BasePart") then return p end
		end
		if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
		local best, score = nil, -1
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") and p.Parent and not isAccessoryPart(p) and not looksLikeWeapon(p.Name) and p.Transparency < 1 then
				local s = p.Size; local sc = s.X*s.Y*s.Z
				if sc > score then best, score = p, sc end
			end
		end
		return best or model:FindFirstChildWhichIsA("BasePart", true)
	end

	local function makeBox(part, col)
		local box = Instance.new("BoxHandleAdornment")
		box.Name = "EnemyESP2_Box"
		box.ZIndex = 5
		box.Color3 = col
		box.AlwaysOnTop = true
		box.Adornee = part
		box.Transparency = 0.25
		-- Smaller than the part for a tighter look
		box.Size = part.Size * 0.8
		box.Parent = M.HOLDER
		return box
	end
	local function makeBill(part, text, col)
		local bill = Instance.new("BillboardGui")
		bill.Name = "EnemyESP2_Label"
		bill.Adornee = part
		bill.AlwaysOnTop = true
		-- Larger label to fit both name and distance
		bill.Size = UDim2.new(0, 140, 0, 36)
		bill.StudsOffset = Vector3.new(0, 2.5, 0)
		bill.MaxDistance = 1e6
		bill.Parent = M.HOLDER

		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.new(1, 0, 0.5, 0)
		tl.Position = UDim2.new(0, 0, 0, 0)
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 12
		tl.TextColor3 = col
		tl.TextStrokeTransparency = 0.3
		tl.Text = text
		tl.Parent = bill

		local distanceLabel = Instance.new("TextLabel")
		distanceLabel.BackgroundTransparency = 1
		distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
		distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
		distanceLabel.Font = Enum.Font.GothamBold
		distanceLabel.TextSize = 12
		distanceLabel.TextColor3 = col
		distanceLabel.TextStrokeTransparency = 0.3
		distanceLabel.Text = "0m"
		distanceLabel.Parent = bill
		return bill, tl, distanceLabel
	end

	local function attachToModel(model)
		if M._records[model] then return end
		if P:GetPlayerFromCharacter(model) then return end
		local b = bucketOf(model); if not b then return end

		local part = pickBodyPart(model); if not part then return end
		local id = b.Name
		local col = colorForBucketName(id)
		local label = getMobDisplayName(model)

		local box = makeBox(part, col)
		local bill, billLabel, distanceLabel = makeBill(part, label, col)

		local rec = {box=box, bill=bill, billLabel=billLabel, distanceLabel=distanceLabel, part=part, conns={}}
		M._records[model] = rec

		table.insert(rec.conns, part:GetPropertyChangedSignal("Size"):Connect(function()
			if rec.box then rec.box.Size = part.Size * 0.8 end
		end))
		table.insert(rec.conns, model.DescendantAdded:Connect(function(inst)
			if inst:IsA("BasePart") then
				local better = pickBodyPart(model)
				if better and better ~= rec.part then
					rec.part = better
					if rec.box then rec.box.Adornee = better end
					if rec.bill then rec.bill.Adornee = better end
				end
			end
		end))
		local function refreshName()
			if rec.billLabel then rec.billLabel.Text = getMobDisplayName(model) end
		end
		local function updateDistance()
			if not rec.distanceLabel or not rec.part then return end
			local char = LP.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local distance = (hrp.Position - rec.part.Position).Magnitude
			local distanceText = string.format("%.0fm", distance)
			rec.distanceLabel.Text = distanceText
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then table.insert(rec.conns, hum:GetPropertyChangedSignal("DisplayName"):Connect(refreshName)) end
		for _, a in ipairs({"EnemyName","DisplayName","NameOverride","MobType","Type"}) do
			table.insert(rec.conns, model:GetAttributeChangedSignal(a):Connect(refreshName))
		end
		table.insert(rec.conns, model.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				clearRecord(rec)
				M._records[model] = nil
			end
		end))
	end

	local function fullScan()
		local root = enemiesRoot(); if not root then return end
		for _, bucket in ipairs(root:GetChildren()) do
			if tonumber(bucket.Name) ~= nil then
				for _, inst in ipairs(bucket:GetDescendants()) do
					if inst:IsA("Model") then attachToModel(inst) end
				end
			end
		end
	end

	table.insert(M._conns, R.Heartbeat:Connect(function() 
		if not M.enabled then return end 
		fullScan()
		-- Update distances for all active mobs
		for _, rec in pairs(M._records) do
			if rec.distanceLabel and rec.part then
				local char = LP.Character
				if char then
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hrp then
						local distance = (hrp.Position - rec.part.Position).Magnitude
						local distanceText = string.format("%.0fm", distance)
						rec.distanceLabel.Text = distanceText
					end
				end
			end
		end
	end))
	local root = enemiesRoot()
	if root then
		table.insert(M._conns, root.DescendantAdded:Connect(function(inst)
			if inst:IsA("Model") then task.defer(function() attachToModel(inst) end) end
		end))
	end

	function M.Disable()
		if not M.enabled then return end
		disableAll()
	end
end

local function RemoveClutter()
	for _,o in ipairs(L:GetChildren())do local c=o.ClassName
		if c=='BloomEffect'or c=='DepthOfFieldEffect'or c=='ColorCorrectionEffect'or c=='SunRaysEffect'or c=='BlurEffect'then pcall(function()o.Enabled=false end)
		elseif c=='Atmosphere'or o.Name=='Atmosphere'or o.Name=='SunRays'then pcall(function()o:Destroy()end)end
	end
	local function nuke(n)local f=workspace:FindFirstChild(n);if f then for _,ch in ipairs(f:GetChildren())do pcall(function()ch:Destroy()end)end end end
	for _,n in ipairs({'Trees','CityProps','Props','Decoration','Grass','VFX','Clouds'})do nuke(n)end
	for _,v in ipairs(workspace:GetDescendants())do pcall(function()
		if v:IsA('ParticleEmitter')or v:IsA('Trail')or v:IsA('Beam')or v:IsA('Smoke')or v:IsA('Fire')or v:IsA('Sparkles')then v.Enabled=false
		elseif v:IsA('Decal')or v:IsA('Texture')then v.Transparency=1
		elseif v:IsA('PointLight')or v:IsA('SpotLight')or v:IsA('SurfaceLight')then if v.Enabled~=nil then v.Enabled=false else v.Brightness=0 end
		elseif v:IsA('MeshPart')then v.RenderFidelity=Enum.RenderFidelity.Performance end
	end)end
end

local function fireAt(v3)local a=ev('Events','Other','Ability');pcall(function()a:InvokeServer('Fireball',v3)end)end
local function UFA(on)
	getgenv().UniversalFireBallAimbot=on;if not on then return end
	
	print('Universal Fireball Aimbot: Starting...')
	
	-- Check if we have any mobs selected
	if not cfg.UFAOrderedMobs or #cfg.UFAOrderedMobs == 0 then
		print('Universal Fireball Aimbot: No mobs selected!')
		return
	end
	
	local currentTargetIndex = 1
	local lastFireballTime = 0
	local lastTargetMob = nil -- Track last targeted mob to prevent duplicates
	local isFiring = false -- Prevent multiple simultaneous fires
	
	task.spawn(function()
		while getgenv().UniversalFireBallAimbot do
			if isFiring then 
				task.wait(0.1)
				continue 
			end
			
			local currentTime = tick()
			if (currentTime - lastFireballTime) >= (cfg.universalFireballInterval or 1.0) then
				local targetMobName = cfg.UFAOrderedMobs[currentTargetIndex]
				if targetMobName == lastTargetMob then
					-- Skip to next mob to avoid duplicates
					currentTargetIndex = currentTargetIndex + 1
					if currentTargetIndex > #cfg.UFAOrderedMobs then 
						currentTargetIndex = 1 
					end
					task.wait(0.2)
					continue
				end
				
				local enemies = workspace:FindFirstChild('Enemies')
				if not enemies then 
					task.wait(0.5)
					continue 
				end
				
				local _, _, hrp = charHum()
				if not hrp then 
					task.wait(0.5)
					continue 
				end
				
				local myPos = hrp.Position
				local bestPart, bestD = nil, math.huge
				local foundMob = false
				
				-- Look for the current target mob type
				for _, bucket in ipairs(enemies:GetChildren()) do
					for _, mob in ipairs(bucket:GetChildren()) do
						if mob:IsA('Model') then
							local dtag = mob:FindFirstChild('Dead')
							local alive = (not dtag or dtag.Value ~= true)
							if alive then
								local mobName = getMobDisplayName(mob)
								if mobName == targetMobName then
									local p = mob:FindFirstChild('HumanoidRootPart')
									if p then 
										local d = (myPos - p.Position).Magnitude
										if d < bestD then 
											bestD = d
											bestPart = p
											foundMob = true
								end
							end
						end
					end
				end
					end
				end
				
				if foundMob and bestPart then
					isFiring = true
					local success = pcall(function() 
						fireAt(bestPart.Position) 
					end)
					
					if success then
						lastFireballTime = currentTime
						lastTargetMob = targetMobName
						currentTargetIndex = currentTargetIndex + 1
						if currentTargetIndex > #cfg.UFAOrderedMobs then 
							currentTargetIndex = 1 
						end
						task.wait(1.0) -- Longer wait after successful fire
					else
						currentTargetIndex = currentTargetIndex + 1
						if currentTargetIndex > #cfg.UFAOrderedMobs then 
							currentTargetIndex = 1 
						end
						task.wait(0.5)
					end
					isFiring = false
				else
					-- No mob of this type found, move to next
					currentTargetIndex = currentTargetIndex + 1
					if currentTargetIndex > #cfg.UFAOrderedMobs then 
						currentTargetIndex = 1 
					end
					task.wait(0.3)
				end
			else
				task.wait(0.1)
			end
		end
	end)
end

local function CatAimbot(on)
	getgenv().FireBallAimbot=on;if not on then return end
	
	print('Catacombs Fireball Aimbot: Starting...')
	local targetOrder={15,14,12,17,13,10,4}
	local currentTargetIndex=1
	local lastFireballTime=0
	local lastTargetFolder=nil -- Track last targeted folder to prevent duplicates
	local isFiring=false -- Prevent multiple simultaneous fires
	
	for i=1,#targetOrder do targetAttempts[i]=0 end
	local fallbackPositions={ [15]=Vector3.new(-200,45,-300),[14]=Vector3.new(-180,50,-280),[12]=Vector3.new(-160,40,-260),[17]=Vector3.new(-220,55,-320),[13]=Vector3.new(-140,45,-240),[10]=Vector3.new(-120,40,-220),[4]=Vector3.new(-100,35,-200)}
	
	task.spawn(function()
		while getgenv().FireBallAimbot do
			local player=P.LocalPlayer
			if player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
				local humanoid=player.Character:FindFirstChild('Humanoid')
				if humanoid and humanoid.Health<=0 then 
					print('Catacombs Fireball Aimbot: Player is dead, stopping...')
					getgenv().FireBallAimbot=false;cfg.FireBallAimbot=false;save();break 
				end
				
				-- Prevent multiple simultaneous fires
				if isFiring then
					task.wait(0.1)
					continue
				end
				
				local currentTime=tick()
				-- Use proper fireball cooldown, not city cooldown
				if (currentTime-lastFireballTime)>=(cfg.fireballCooldown or 0.3) then
					local targetFolderNumber=targetOrder[currentTargetIndex]
					
					-- Skip if we just targeted this folder (prevent duplicate firing)
					if targetFolderNumber == lastTargetFolder then
						currentTargetIndex=currentTargetIndex+1
						if currentTargetIndex>#targetOrder then currentTargetIndex=1 end
						task.wait(0.2)
						continue
					end
					
					print('Catacombs Fireball Aimbot: TARGETING folder ' .. targetFolderNumber .. ' (Index: ' .. currentTargetIndex .. '/7)')
					local enemies=workspace:FindFirstChild('Enemies')
					
					if enemies then
						local targetFolder=enemies:FindFirstChild(tostring(targetFolderNumber))
						if targetFolder and targetFolder:IsA('Folder') then
							local children=targetFolder:GetChildren()
							print('Catacombs Fireball Aimbot: Checking folder ' .. targetFolderNumber .. ' with ' .. #children .. ' children')
							
							local targetPosition=nil
							local foundMob=false
							
							for _,child in pairs(children)do
								if child:IsA('Model') and child:FindFirstChild('HumanoidRootPart') then
									local hrp=child:FindFirstChild('HumanoidRootPart')
									if hrp and hrp.Position then 
										targetPosition=hrp.Position;foundMob=true
										print('Catacombs Fireball Aimbot: Found Model mob "' .. child.Name .. '" at ' .. tostring(targetPosition))
										break 
									end
								elseif child:IsA('BasePart') and child.Position and child.Position~=Vector3.new(0,0,0) then
									targetPosition=child.Position;foundMob=true
									print('Catacombs Fireball Aimbot: Found BasePart mob "' .. child.Name .. '" at ' .. tostring(targetPosition))
									break
								end
							end
							
							if not foundMob then 
								targetPosition=fallbackPositions[targetFolderNumber] or Vector3.new(targetFolderNumber*20,5,targetFolderNumber*10)
								print('Catacombs Fireball Aimbot: No mobs in folder ' .. targetFolderNumber .. ', firing at strategic position ' .. tostring(targetPosition))
							end
							
							-- Set firing flag to prevent duplicates
							isFiring=true
							local success=pcall(function()fireAt(targetPosition)end)
							
							if success then
								if foundMob then
									print('Catacombs Fireball Aimbot: Fired at folder ' .. targetFolderNumber .. ' (' .. currentTargetIndex .. '/7) mob position ' .. tostring(targetPosition))
								else
									print('Catacombs Fireball Aimbot: Fired at folder ' .. targetFolderNumber .. ' (' .. currentTargetIndex .. '/7) calculated position ' .. tostring(targetPosition))
								end
								lastFireballTime=currentTime
								lastTargetFolder=targetFolderNumber
								
								-- Move to next target
								currentTargetIndex=currentTargetIndex+1
								if currentTargetIndex>#targetOrder then 
									currentTargetIndex=1
									print('Catacombs Fireball Aimbot: Completed cycle, restarting...')
								end
								
								-- Wait longer before next target to prevent rapid firing
								task.wait(1.0)
							else
								print('Catacombs Fireball Aimbot: Failed to fire at folder ' .. targetFolderNumber .. ', moving to next...')
								currentTargetIndex=currentTargetIndex+1
								if currentTargetIndex>#targetOrder then currentTargetIndex=1 end
								task.wait(0.5)
							end
							
							-- Clear firing flag
							isFiring=false
						else
							print('Catacombs Fireball Aimbot: Folder ' .. targetFolderNumber .. ' not found, moving to next...')
							currentTargetIndex=currentTargetIndex+1
							if currentTargetIndex>#targetOrder then currentTargetIndex=1 end
							task.wait(0.3)
						end
					else
						print('Catacombs Fireball Aimbot: workspace.Enemies not found')
						task.wait(0.5)
					end
				else
					task.wait(0.1)
				end
			else
				task.wait(0.1)
			end
		end
	end)
end

local function CityAimbot(on)
	getgenv().FireBallAimbotCity=on;if not on then return end
	
	print('City Fireball Aimbot: Starting...')
	local targetOrder={6,9,5,3,2}
	local currentTargetIndex=1
	local lastFireballTime=0
	local lastTargetFolder=nil -- Track last targeted folder to prevent duplicates
	local isFiring=false -- Prevent multiple simultaneous fires
	
	-- Strategic fallback positions for empty folders (near typical city spawn areas)
	local fallbackPositions = {
		[6] = Vector3.new(140, 30, 100),  -- City area 6
		[9] = Vector3.new(200, 30, 160),  -- City area 9
		[5] = Vector3.new(120, 25, 80),   -- City area 5
		[3] = Vector3.new(80, 20, 60),    -- City area 3
		[2] = Vector3.new(60, 25, 40),    -- City area 2
	}
	
	task.spawn(function()
		while getgenv().FireBallAimbotCity do
			local player=P.LocalPlayer
			if player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
				local humanoid=player.Character:FindFirstChild('Humanoid')
				if humanoid and humanoid.Health<=0 then 
					print('City Fireball Aimbot: Player is dead, stopping...')
					getgenv().FireBallAimbotCity=false;cfg.FireBallAimbotCity=false;save();break 
				end
				
				-- Prevent multiple simultaneous fires
				if isFiring then
					task.wait(0.1)
					continue
				end
				
				local currentTime=tick()
				if (currentTime-lastFireballTime)>=(cfg.cityFireballCooldown or 0.3) then
					local targetFolderNumber=targetOrder[currentTargetIndex]
					
					-- Skip if we just targeted this folder (prevent duplicate firing)
					if targetFolderNumber == lastTargetFolder then
						currentTargetIndex=currentTargetIndex+1
						if currentTargetIndex>#targetOrder then currentTargetIndex=1 end
						task.wait(0.2)
						continue
					end
					
					print('City Fireball Aimbot: TARGETING folder ' .. targetFolderNumber .. ' (Index: ' .. currentTargetIndex .. '/5)')
					local enemies=workspace:FindFirstChild('Enemies')
					
					if enemies then
						local targetFolder=enemies:FindFirstChild(tostring(targetFolderNumber))
						if targetFolder and targetFolder:IsA('Folder') then
							local children=targetFolder:GetChildren()
							print('City Fireball Aimbot: Checking folder ' .. targetFolderNumber .. ' with ' .. #children .. ' children')
							
							local targetPosition=nil
							local foundMob=false
							
							for _,child in pairs(children)do
								if child:IsA('Model') and child:FindFirstChild('HumanoidRootPart') then
									local hrp=child:FindFirstChild('HumanoidRootPart')
									if hrp and hrp.Position then 
										targetPosition=hrp.Position;foundMob=true
										print('City Fireball Aimbot: Found Model mob "' .. child.Name .. '" at ' .. tostring(targetPosition))
										break 
									end
								elseif child:IsA('BasePart') and child.Position and child.Position~=Vector3.new(0,0,0) then
									targetPosition=child.Position;foundMob=true
									print('City Fireball Aimbot: Found BasePart mob "' .. child.Name .. '" at ' .. tostring(targetPosition))
									break
								end
							end
							
							if not foundMob then 
								targetPosition=fallbackPositions[targetFolderNumber] or Vector3.new(targetFolderNumber*20,5,targetFolderNumber*10)
								print('City Fireball Aimbot: No mobs in folder ' .. targetFolderNumber .. ', firing at strategic position ' .. tostring(targetPosition))
							end
							
							-- Set firing flag to prevent duplicates
							isFiring=true
							local success=pcall(function()fireAt(targetPosition)end)
							
							if success then
								if foundMob then
									print('City Fireball Aimbot: Fired at folder ' .. targetFolderNumber .. ' (' .. currentTargetIndex .. '/5) mob position ' .. tostring(targetPosition))
								else
									print('City Fireball Aimbot: Fired at folder ' .. targetFolderNumber .. ' (' .. currentTargetIndex .. '/5) calculated position ' .. tostring(targetPosition))
								end
							lastFireballTime=currentTime
								lastTargetFolder=targetFolderNumber
								
								-- Move to next target
								currentTargetIndex=currentTargetIndex+1
								if currentTargetIndex>#targetOrder then 
									currentTargetIndex=1
									print('City Fireball Aimbot: Cycle completed, restarting...')
								end
								
								-- Wait longer before next target to prevent rapid firing
								task.wait(1.0)
							else
								print('City Fireball Aimbot: Failed to fire at folder ' .. targetFolderNumber .. ', moving to next...')
							currentTargetIndex=currentTargetIndex+1
							if currentTargetIndex>#targetOrder then currentTargetIndex=1 end
								task.wait(0.5)
							end
							
							-- Clear firing flag
							isFiring=false
						else
							print('City Fireball Aimbot: Folder ' .. targetFolderNumber .. ' not found, moving to next target...')
							currentTargetIndex=currentTargetIndex+1
							if currentTargetIndex>#targetOrder then currentTargetIndex=1 end
							task.wait(0.3)
						end
					else
						print('City Fireball Aimbot: workspace.Enemies not found')
						task.wait(0.5)
					end
				else
					task.wait(0.1)
				end
			else
				task.wait(0.1)
			end
		end
	end)
end

local function sideLoop(gk,ck,id)
	getgenv()[gk]=true
	task.spawn(function()
		while getgenv()[gk] do
			pcall(function()
				local _,h=charHum();if h and h.Health<=0 then getgenv()[gk]=false;cfg[ck]=false;save();return end
				local o=ev('Events','Other');o:WaitForChild('StartSideTask',9e9):FireServer(id);if id==1 then pcall(function()o:WaitForChild('CleanDishes',9e9):FireServer()end)end
				o:WaitForChild('ClaimSideTask',9e9):FireServer(id)
			end)
			task.wait(math.random(50,70))
		end
	end)
end
local function TWash(on)getgenv().AutoWashDishes=on;if on then sideLoop('AutoWashDishes','AutoWashDishes',1)end end
local function TNinja(on)cfg.AutoNinjaSideTask=on;save();if on then sideLoop('AutoNinjaSideTask','AutoNinjaSideTask',9)else getgenv().AutoNinjaSideTask=false end end
local function TAnim(on)cfg.AutoAnimatronicsSideTask=on;save();if on then sideLoop('AutoAnimatronicsSideTask','AutoAnimatronicsSideTask',10)else getgenv().AutoAnimatronicsSideTask=false end end
local function TMut(on)cfg.AutoMutantsSideTask=on;save();if on then sideLoop('AutoMutantsSideTask','AutoMutantsSideTask',7)else getgenv().AutoMutantsSideTask=false end end

local function TDualExotic(on)
	cfg.DualExoticShop=on;save();getgenv().DualExoticShop=on
	if not on then return end

	task.spawn(function()
		task.wait(10)

		local player = LP
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		player.CharacterAdded:Connect(function(newCharacter)
			character = newCharacter
			humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
		end)

		local remote1 = RS:WaitForChild("Events"):WaitForChild("Spent"):WaitForChild("BuyExotic")
		local remote2 = RS:WaitForChild("Events"):WaitForChild("GiveItemRequest2")
		local remote2Old = RS:WaitForChild("Events"):WaitForChild("Spent"):WaitForChild("BuyExotic2")

		local guiFolder = player.PlayerGui:WaitForChild("Frames")
		local gui1 = guiFolder:WaitForChild("ExoticStore")
		local gui2 = guiFolder:WaitForChild("ExoticStore2")

		local function getPadPart(padModel)
			if not padModel then return nil end
			if padModel:IsA("BasePart") then return padModel end
			if padModel:IsA("Model") then return padModel:FindFirstChildWhichIsA("BasePart") end
			return nil
		end

		local pad1 = getPadPart(workspace.Pads.ExoticStore["1"])
		local pad2 = getPadPart(workspace.Pads.ExoticStore2["1"])

		local function buyPotions(shopFrame, remote, isExoticStore2)
			if not shopFrame or not remote then return end
			local content = shopFrame:FindFirstChild("Content")
			local list = content and content:FindFirstChild("ExoticList")
			if not list then return end

			for _, v in pairs(list:GetChildren()) do
				local info = v:FindFirstChild("Info")
				local info2 = info and info:FindFirstChild("Info")
				if info2 and info2.Text == "POTION" then
					local itemNumber = tonumber(string.match(v.Name, "%d+"))
					if itemNumber then
						task.wait(0.1)
						pcall(function() remote:FireServer(itemNumber) end)
						if isExoticStore2 then
							pcall(function() remote2Old:FireServer(itemNumber) end)
						end
					end
				end
			end
		end

		local function safeTeleport(targetCFrame)
			if not humanoidRootPart or not humanoidRootPart.Parent then return false end
			humanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
			task.wait(3)
			return true
		end

		local lastDarkStoreTime = 0
		local lastRegularStoreTime = 0
		local DARK_STORE_INTERVAL = 3600 -- 60 minutes in seconds
		local REGULAR_STORE_INTERVAL = 1200 -- 20 minutes in seconds

		while getgenv().DualExoticShop do
			local currentTime = tick()
			local success = pcall(function()
				local originalCFrame = humanoidRootPart.CFrame

				-- Buy from Exotic Store 1 every 20 minutes
				local timeSinceLastRegularStore = currentTime - lastRegularStoreTime
				if timeSinceLastRegularStore >= REGULAR_STORE_INTERVAL and pad1 and gui1 and remote1 then
					if safeTeleport(pad1.CFrame) then
					buyPotions(gui1, remote1, false)
					humanoidRootPart.CFrame = originalCFrame
						lastRegularStoreTime = currentTime
					task.wait(3)
					end
				end

				-- Buy from Dark Exotic Store 2 every 60 minutes
				local timeSinceLastDarkStore = currentTime - lastDarkStoreTime
				if timeSinceLastDarkStore >= DARK_STORE_INTERVAL and pad2 and gui2 and remote2 then
					if safeTeleport(pad2.CFrame) then
					buyPotions(gui2, remote2, true)
					humanoidRootPart.CFrame = originalCFrame
						lastDarkStoreTime = currentTime
					task.wait(3)
					end
				end
			end)

			if not success then task.wait(30) end

			-- Wait 1 minute before next check
			for i=1,60 do
				if not getgenv().DualExoticShop then break end
				task.wait(1)
			end
		end
	end)
end

local function TVend(on)getgenv().VendingPotionAutoBuy=on;if on then task.spawn(function()local b=ev('Events','VendingMachine','BuyPotion');local a={{2,5000},{3,15000},{1,1500},{4,150000},{5,1500000}}
	while getgenv().VendingPotionAutoBuy do for _,x in ipairs(a)do if not getgenv().VendingPotionAutoBuy then break end pcall(function()b:FireServer(unpack(x))end)for i=1,60 do if not getgenv().VendingPotionAutoBuy then break end task.wait(1)end end end
end)end end

local function TStatWH(on)cfg.StatWebhook15m=on;save();getgenv().StatWebhook15m=on;if not on then return end
	task.spawn(function()
		local st=RS:WaitForChild('Data'):WaitForChild(LP.Name):WaitForChild('Stats')
		local op,od,oh,om,oy,omob,ot=st.Power.Value,st.Defense.Value,st.Health.Value,st.Magic.Value,st.Psychics.Value,st.Mobility.Value,st.Tokens.Value
		local function fmt(n)n=tonumber(n)or 0;if n>=1e18 then return string.format('%.2f',n/1e18)..'QN' end;if n>=1e15 then return string.format('%.2f',n/1e15)..'qd' end;if n>=1e12 then return string.format('%.2f',n/1e12)..'t' end
			if n>=1e9 then return string.format('%.2f',n/1e9)..'b'end;if n>=1e6 then return string.format('%.2f',n/1e6)..'m'end;if n>=1e3 then return string.format('%.2f',n/1e3)..'k'end return tostring(n)end
		local function fmtChange(n)local change=tonumber(n)or 0;local sign=change>=0 and '+'or'';return sign..fmt(math.abs(change))end
		while getgenv().StatWebhook15m do for i=1,900 do if not getgenv().StatWebhook15m then break end task.wait(1)end;if not getgenv().StatWebhook15m then break end
			local np,nd,nh,nm,ny,nmob,nt=st.Power.Value,st.Defense.Value,st.Health.Value,st.Magic.Value,st.Psychics.Value,st.Mobility.Value,st.Tokens.Value
			if np>op or nd>od or nh>oh or nm>om or ny>oy or nmob>omob or nt~=ot then
				local t=LP.Name..' Stats Gained Last 15 Minutes'
				local d='💪 **Power:** '..fmt(np)..' → **'..fmt(np-op)..'**\n❤️ **Health:** '..fmt(nh)..' → **'..fmt(nh-oh)..'**\n🛡️ **Defense:** '..fmt(nd)..' → **'..fmt(nd-od)..'**\n🔮 **Psychics:** '..fmt(ny)..' → **'..fmt(ny-oy)..'**\n✨ **Magic:** '..fmt(nm)..' → **'..fmt(nm-om)..'**\n💨 **Mobility:** '..fmt(nmob)..' → **'..fmt(nmob-omob)..'**\n💰 **Tokens:** '..fmt(nt)..' → **'..fmtChange(nt-ot)..'**'
				webhook('Stat Bot',t,d,nil);op,od,oh,om,oy,omob,ot=np,nd,nh,nm,ny,nmob,nt
			end
		end
	end)
end

local KA
local function TKA(on)cfg.KillAura=on;save();getgenv().KillAura=on;if KA then KA:Disconnect();KA=nil end;if not on then return end
	KA=R.Heartbeat:Connect(function()
		local _,_,hrp=charHum();if not hrp then return end
		local E=workspace:FindFirstChild('Enemies');if not E then return end
		for _,f in ipairs(E:GetChildren())do for _,e in ipairs(f:GetChildren())do if e:IsA('Model')then local p=e:FindFirstChild('HumanoidRootPart');local d=e:FindFirstChild('Dead')
			if p and(not d or d.Value~=true)then local dist=(hrp.Position-p.Position).Magnitude;if dist<=500 then pcall(function()RS.Events.Other.Ability:InvokeServer('Weapon')end)end end end end end
	end)
end

-- Auto Block (spam while under full HP)
local AB={conn=nil,charConn=nil,loop=nil}
local function TAutoBlock(on)
	cfg.AutoBlock=on;save();getgenv().AutoBlock=on
	local function stop()if AB.conn then AB.conn:Disconnect() AB.conn=nil end;if AB.charConn then AB.charConn:Disconnect() AB.charConn=nil end;if AB.loop then AB.loop:Disconnect() AB.loop=nil end end
	if not on then stop();return end
	local function startLoop(h)
		if AB.loop then AB.loop:Disconnect() AB.loop=nil end
		if not h then return end
		local last=0
		AB.loop=R.Heartbeat:Connect(function()
			if not getgenv().AutoBlock then return end
			if not h.Parent or h.Health<=0 then return end
			if h.MaxHealth and h.Health<h.MaxHealth then
				local now=os.clock()
				if now-last>=0.1 then
					last=now
					pcall(function()ev('Events','Other','Ability'):InvokeServer('Block',Vector3.new(-938.988037109375,-1597.0552978515625,-3059.690673828125))end)
				end
			end
		end)
	end
	AB.charConn=LP.CharacterAdded:Connect(function(c)local h=c:WaitForChild('Humanoid',10)startLoop(h)end)
	local c=LP.Character or LP.CharacterAdded:Wait()
	startLoop(c:FindFirstChildOfClass('Humanoid'))
end

-- Combat Log (kick under 10% HP)
local CL={conn=nil}
local function TCombatLog(on)
	cfg.CombatLog=on;save();getgenv().CombatLog=on
	if CL.conn then CL.conn:Disconnect() CL.conn=nil end
	if not on then return end
	local function hook(h)
		if not h then return end
		if CL.conn then CL.conn:Disconnect() CL.conn=nil end
		CL.conn=h.HealthChanged:Connect(function(hp)
			if not getgenv().CombatLog then return end
			if h.MaxHealth and h.MaxHealth>0 and hp>0 then
				if hp<=0.25*h.MaxHealth then
	pcall(function()
		webhook('Combat Log Bot','Combat Log',LP.Name..' left at '..math.floor((hp/h.MaxHealth)*100)..'% HP',WID)
	end)
	pcall(function()LP:Kick('Combat Log')end)
end
			end
		end)
	end
	local c=LP.Character or LP.CharacterAdded:Wait()
	hook(c:FindFirstChildOfClass('Humanoid'))
	LP.CharacterAdded:Connect(function(nc) hook(nc:WaitForChild('Humanoid',10)) end)
end

local SG={gui=nil,run=false}
local function TStatGui(on)cfg.StatGui=on;save();getgenv().StatGui=on;if not on then SG.run=false;if SG.gui then pcall(function()SG.gui:Destroy()end)SG.gui=nil end return end
	-- retained but no UI toggle
end

local QuickTeleportsGUI = nil
local function TQuickTeleports(on)
	cfg.QuickTeleports = on
	save()
	getgenv().QuickTeleports = on
	if not on then if QuickTeleportsGUI then pcall(function() QuickTeleportsGUI:Destroy() end) QuickTeleportsGUI=nil end return end
	local Players=game:GetService("Players");local ReplicatedStorage=game:GetService("ReplicatedStorage");local LocalPlayer=Players.LocalPlayer
	local ScreenGui=Instance.new("ScreenGui")ScreenGui.ResetOnSpawn=false ScreenGui.Parent=LocalPlayer:WaitForChild("PlayerGui") QuickTeleportsGUI=ScreenGui
	local Frame=Instance.new("Frame")Frame.Size=UDim2.new(0,180,0,240)Frame.Position=UDim2.new(0,20,1,-260)Frame.BackgroundColor3=Color3.fromRGB(30,30,30)Frame.BorderSizePixel=0 Frame.Active=true Frame.Draggable=true Frame.Parent=ScreenGui
	local UICorner=Instance.new("UICorner")UICorner.CornerRadius=UDim.new(0,8)UICorner.Parent=Frame
	local Title=Instance.new("TextLabel")Title.Size=UDim2.new(1,0,0,25)Title.BackgroundTransparency=1 Title.Text="Teleports"Title.TextColor3=Color3.fromRGB(255,255,255)Title.TextSize=14 Title.Font=Enum.Font.GothamSemibold Title.Parent=Frame
	local function createButton(name,onClick,y)local Button=Instance.new("TextButton")Button.Size=UDim2.new(0,160,0,30)Button.Position=UDim2.new(0.5,-80,0,y)Button.Text=name Button.Font=Enum.Font.Gotham Button.TextSize=12 Button.BackgroundColor3=Color3.fromRGB(45,45,45)Button.TextColor3=Color3.fromRGB(255,255,255)Button.BorderSizePixel=0 Button.Parent=Frame local UIC=Instance.new("UICorner")UIC.CornerRadius=UDim.new(0,4)UIC.Parent=Button Button.MouseEnter:Connect(function()Button.BackgroundColor3=Color3.fromRGB(60,60,60)end)Button.MouseLeave:Connect(function()Button.BackgroundColor3=Color3.fromRGB(45,45,45)end)Button.MouseButton1Click:Connect(function()pcall(onClick)end)end
	local function tpToQuick(target)if not target then return end local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()local hrp=char:WaitForChild("HumanoidRootPart")local cf=target:IsA("BasePart") and target.CFrame or (target.IsA and target:IsA("Model") and target:GetPivot() or nil)if not cf then return end hrp.CFrame=cf+Vector3.new(0,3,0)end
	local function resolveHeavensDoorPart()local ok,res=pcall(function()local hd=workspace:FindFirstChild("HeavensDoor")return hd and hd:GetChildren()[10] or nil end)return ok and res or nil end
	local function resolveUndergroundQDoorPart()local ok,res=pcall(function()local gm=workspace:FindFirstChild("GameMap");local ug=gm and gm:FindFirstChild("Underground");local c=ug and ug:FindFirstChild("R237G234B234");local qd=c and c:FindFirstChild("? Door");local mdl=qd and qd:FindFirstChild("Model")return mdl and mdl:GetChildren()[2] or nil end)return ok and res or nil end
	local function resolveIceCrystalPart()local ok,res=pcall(function()local child=workspace:GetChildren()[95];local ic=child and child:FindFirstChild("Ice Crystal")return ic and ic:GetChildren()[2] or nil end)return ok and res or nil end
	local function resolveCatacombsCityPart()local ok,res=pcall(function()local city=workspace:FindFirstChild("CatacombsCity")return city and city:GetChildren()[3074] or nil end)return ok and res or nil end
	local function resolveHellMapUnion()local ok,res=pcall(function()local hm=workspace:FindFirstChild("HellMap")return hm and hm:FindFirstChild("Union") or nil end)return ok and res or nil end
	local function resolveFireCrystalPart()local ok,res=pcall(function()local child=workspace:GetChildren()[117];local child7=child and child:GetChildren()[7];local mdl=child7 and child7:FindFirstChild("Model");local mdl2=mdl and mdl:FindFirstChild("Model");local fc=mdl2 and mdl2:FindFirstChild("Fire Crystal")return fc and fc:GetChildren()[2] or nil end)return ok and res or nil end
	local function resolvePower30()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local pwr=ti and ti:FindFirstChild("Power")return pwr and pwr:FindFirstChild("30") or nil end)return ok and res or nil end
	local function resolveHellMapPower()local ok,res=pcall(function()local hm=workspace:FindFirstChild("HellMap")return hm and hm:GetChildren()[2729] or nil end)return ok and res or nil end
	local function resolvePower28()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local pwr=ti and ti:FindFirstChild("Power")return pwr and pwr:FindFirstChild("28") or nil end)return ok and res or nil end
	local function resolveMeteoriteOrb()local ok,res=pcall(function()local meteorite=workspace:FindFirstChild("meteorite for psl")return meteorite and meteorite:FindFirstChild("orb") or nil end)return ok and res or nil end
	local function resolveMagicPart()local ok,res=pcall(function()local child=workspace:GetChildren()[136]return child and child:FindFirstChild("Part") or nil end)return ok and res or nil end
	local function resolveMagic15()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("15") or nil end)return ok and res or nil end
	local function resolveMagic14()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("14") or nil end)return ok and res or nil end
	local function resolveMagic13()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("13") or nil end)return ok and res or nil end
	local function resolveMagic12()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local mag=ti and ti:FindFirstChild("Magic")return mag and mag:FindFirstChild("12") or nil end)return ok and res or nil end
	local function resolvePsychicTree()local ok,res=pcall(function()local gm=workspace:FindFirstChild("GameMap");local ug=gm and gm:FindFirstChild("Underground");local c=ug and ug:FindFirstChild("R237G234B234");local child5=c and c:GetChildren()[5];local mdl=child5 and child5:FindFirstChild("Model");local tree=mdl and mdl:FindFirstChild("Tree3")return tree and tree:FindFirstChild("Trunk") or nil end)return ok and res or nil end
	local function resolvePsychic28()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("28") or nil end)return ok and res or nil end
	local function resolvePsychic27()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("27") or nil end)return ok and res or nil end
	local function resolvePsychic24()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("24") or nil end)return ok and res or nil end
	local function resolvePsychic23()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("23") or nil end)return ok and res or nil end
	local function resolvePsychic22()local ok,res=pcall(function()local ti=workspace:FindFirstChild("TrainingInterface");local psy=ti and ti:FindFirstChild("Psychics")return psy and psy:FindFirstChild("22") or nil end)return ok and res or nil end
	local function tpToQuick(target)if not target then return end local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()local hrp=char:WaitForChild("HumanoidRootPart")local cf=target:IsA("BasePart") and target.CFrame or (target.IsA and target:IsA("Model") and target:GetPivot() or nil)if not cf then return end hrp.CFrame=cf+Vector3.new(0,3,0)end
	local function bestDefenseTeleportQ()local stats=ReplicatedStorage:WaitForChild("Data"):WaitForChild(LocalPlayer.Name):WaitForChild("Stats");local v=stats and stats:FindFirstChild("Defense") and stats.Defense.Value or 0;local zones={{req=1e20,getter=resolveHeavensDoorPart},{req=1e19,getter=resolveUndergroundQDoorPart},{req=1e18,getter=resolveIceCrystalPart},{req=1e17,getter=resolveCatacombsCityPart},{req=1e16,getter=resolveHellMapUnion}}for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpToQuick(inst) return end end end end
	local function bestPowerTeleportQ()local stats=ReplicatedStorage:WaitForChild("Data"):WaitForChild(LocalPlayer.Name):WaitForChild("Stats");local v=stats and stats:FindFirstChild("Power") and stats.Power.Value or 0;local zones={{req=1e20,getter=resolveFireCrystalPart},{req=1e19,getter=resolvePower30},{req=1e18,getter=resolveHellMapPower},{req=1e17,getter=resolvePower28},{req=1e16,getter=resolveMeteoriteOrb}}for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpToQuick(inst) return end end end end
	local function bestMagicTeleportQ()local stats=ReplicatedStorage:WaitForChild("Data"):WaitForChild(LocalPlayer.Name):WaitForChild("Stats");local v=stats and stats:FindFirstChild("Magic") and stats.Magic.Value or 0;local zones={{req=1e20,getter=resolveMagicPart},{req=1e19,getter=resolveMagic15},{req=1e18,getter=resolveMagic14},{req=1e17,getter=resolveMagic13},{req=5e15,getter=resolveMagic12}}for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpToQuick(inst) return end end end end
	local function bestPsychicTeleportQ()local stats=ReplicatedStorage:WaitForChild("Data"):WaitForChild(LocalPlayer.Name):WaitForChild("Stats");local v=stats and stats:FindFirstChild("Psychics") and stats.Psychics.Value or 0;local zones={{req=1e20,getter=resolvePsychicTree},{req=1e19,getter=resolvePsychic28},{req=1e18,getter=resolvePsychic27},{req=1e17,getter=resolvePsychic24},{req=5e16,getter=resolvePsychic23},{req=5e15,getter=resolvePsychic22}}for _,z in ipairs(zones)do if v>=z.req then local inst=z.getter();if inst then tpToQuick(inst) return end end end end
	createButton("Dark Exotic Store",function()local p=workspace:FindFirstChild("Pads");local s2=p and p:FindFirstChild("ExoticStore2");local pad=s2 and s2:FindFirstChild("1");tpToQuick(pad)end,30)
	createButton("Best Defense Area",bestDefenseTeleportQ,65)
	createButton("Best Power Area",bestPowerTeleportQ,100)
	createButton("Best Magic Area",bestMagicTeleportQ,135)
	createButton("Best Psychic Area",bestPsychicTeleportQ,170)
	createButton("Teleport To Save",function()
		local cf=_G.__SavedCFrame or savedCFrame
		if not cf then loadPersistedSave(); cf=savedCFrame end
		if not cf then return end
		local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		pcall(function()char:PivotTo(cf)end)
	end,205)
end

local AA={inv=nil,res=nil,fly=nil}
local function TInv(on)cfg.AutoInvisible=on;save();getgenv().AutoInvisible=on;if AA.inv then AA.inv:Disconnect()AA.inv=nil end;if not on then return end
	local a=ev('Events','Other','Ability');local last=0
	AA.inv=R.Heartbeat:Connect(function()local n=os.clock();if n-last<0.5 then return end;last=n;local tv=LP:FindFirstChild('TempValues');local f=tv and tv:FindFirstChild('IsInvisible');if not(f and f.Value==true)then pcall(function()a:InvokeServer('Invisibility',Vector3.new(1936.171142578125,56.015625,-1960.4375))end)end end)
end
local function TResize(on)cfg.AutoResize=on;save();getgenv().AutoResize=on;if AA.res then AA.res:Disconnect()AA.res=nil end;if not on then return end
	local a=ev('Events','Other','Ability');local last=0
	AA.res=R.Heartbeat:Connect(function()local n=os.clock();if n-last<0.5 then return end;last=n;local tv=LP:FindFirstChild('TempValues');local f=tv and tv:FindFirstChild('IsResized');if not(f and f.Value==true)then pcall(function()a:InvokeServer('Resize',Vector3.new(1936.959228515625,56.015625,-1974.80908203125))end)end end)
end
local function TFly(on)cfg.AutoFly=on;save();getgenv().AutoFly=on;if AA.fly then AA.fly:Disconnect()AA.fly=nil end;if not on then return end
	local a=ev('Events','Other','Ability');local last=0
	AA.fly=R.Heartbeat:Connect(function()local n=os.clock();if n-last<0.5 then return end;last=n;local tv=LP:FindFirstChild('TempValues');local f=tv and tv:FindFirstChild('IsFlying');if not(f and f.Value==true)then pcall(function()a:InvokeServer('Fly',Vector3.new(1932.461181640625,56.015625,-1965.3206787109375))end)end end)
end

local HExp
local function resolvePart(which)
	local path=which=='low'and(getgenv and getgenv().HealthPart15Path)or(getgenv and getgenv().HealthPart95Path)
	if type(path)=='string' and path:find('workspace:') then
		local success,result=pcall(function()
			local indices={}for index in path:gmatch('%[(%d+)%]') do table.insert(indices,tonumber(index))end
			if #indices>=2 then local container=workspace:GetChildren()[indices[1]];if container then return container:GetChildren()[indices[2]] end
			elseif #indices==1 and path:find('workspace:GetChildren()') then return workspace:GetChildren()[indices[1]] end
			return nil
		end)
		if success and result then return result end
	end
	if type(path)=='string' and path:match('^workspace%.') then
		local success,result=pcall(function()return loadstring('return '..path)() end)
		if success and result then return result end
	end
	local city=workspace:FindFirstChild('CatacombsCity');if not city then return nil end
	local kids=city:GetChildren()
	local idx=tonumber(type(path)=='string'and path:match('%[(%d+)%]')or nil);if not idx then idx=(which=='low')and 2145 or 2389 end
	return kids[idx]
end
local function THealthExploit(on)cfg.HealthExploit=on;save();getgenv().HealthExploit=on;if HExp then HExp:Disconnect()HExp=nil end;if not on then return end
	local last=0
	HExp=R.Heartbeat:Connect(function()local n=os.clock();if n-last<0.5 then return end;last=n;local c,h=charHum();if not(c and h and h.MaxHealth and h.MaxHealth>0 and h.Health>0)then return end
		local r=h.Health/h.MaxHealth;if r<=0.15 then local p=resolvePart('low');if p and p.CFrame then pcall(function()c:PivotTo(p.CFrame+Vector3.new(0,3,0))end)end
		elseif r>=0.95 then local p=resolvePart('high');if p and p.CFrame then pcall(function()c:PivotTo(p.CFrame+Vector3.new(0,3,0))end)end end
	end)
end

local function nearestNonSafePlayer()
	local _,_,hrp=charHum();if not hrp then return nil end
	local ignored={["1nedu"]=true,["209flaw"]=true}
	local best,bestD=nil,math.huge
	for _,p in ipairs(P:GetPlayers())do
		if p~=LP and not ignored[p.Name] and p.Character and p.Character:FindFirstChild('HumanoidRootPart')then
			local tv=p:FindFirstChild('TempValues');local sz=tv and tv:FindFirstChild('SafeZone')
			if not sz or sz.Value~=1 then
				local d=(hrp.Position-p.Character.HumanoidRootPart.Position).Magnitude
				if d<bestD then best,bestD=p,d end
			end
		end
	end
	return best
end
local function fireGammaAt(pos)local a=ev('Events','Other','Ability');pcall(function()a:InvokeServer('Gamma Ray',pos)end)end
local GConn
local function TGamma(on)cfg.GammaAimbot=on;save();getgenv().GammaAimbot=on
	if GConn then GConn:Disconnect()GConn=nil end
	if on then
		GConn=U.InputBegan:Connect(function(i,gp)
			if gp then return end
			if i.KeyCode==Enum.KeyCode.G then
				local t=nearestNonSafePlayer()
				if t and t.Character and t.Character:FindFirstChild('HumanoidRootPart')then
					fireGammaAt(t.Character.HumanoidRootPart.Position)
				end
			end
		end)
	end
end

local function TInfiniteZoom(on)
	cfg.InfiniteZoom=on;save();getgenv().InfiniteZoom=on
	if on then
		task.spawn(function()
			while getgenv().InfiniteZoom do
				pcall(function()
					LP.CameraMaxZoomDistance = math.huge
					LP.CameraMinZoomDistance = 0.5
					Cam.CameraType = Enum.CameraType.Custom
					pcall(function() LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)
				end)
				task.wait(1)
			end
		end)
	end
end

-- Potion consumption
local function consumePotion(statType)
	local Players=game:GetService("Players");local ReplicatedStorage=game:GetService("ReplicatedStorage");local LocalPlayer=Players.LocalPlayer
	local inventoryList=LocalPlayer.PlayerGui.Frames.Inventory.Content.Inventory.List.List
	local equipRemote=ReplicatedStorage:WaitForChild("Events"):WaitForChild("Inventory"):WaitForChild("EquipItem")
	local potionLists={Power={["Power Barrel"]=true,["Power Bottle"]=true,["Power Crate"]=true,["Power Drink"]=true,["Power Potion"]=true},Health={["Health Barrel"]=true,["Health Bottle"]=true,["Health Crate"]=true,["Health Drink"]=true,["Health Potion"]=true},Defense={["Defense Barrel"]=true,["Defense Bottle"]=true,["Defense Crate"]=true,["Defense Drink"]=true,["Defense Potion"]=true},Psychic={["Psychics Barrel"]=true,["Psychics Bottle"]=true,["Psychics Crate"]=true,["Psychics Drink"]=true,["Psychics Potion"]=true},Magic={["Magic Barrel"]=true,["Magic Bottle"]=true,["Magic Crate"]=true,["Magic Drink"]=true,["Magic Potion"]=true},Mobility={["Mobility Barrel"]=true,["Mobility Bottle"]=true,["Mobility Crate"]=true,["Mobility Drink"]=true,["Mobility Potion"]=true},Super={["Super Barrel"]=true,["Super Bottle"]=true,["Super Crate"]=true,["Super Drink"]=true,["Super Potion"]=true}}
	while getgenv()["AutoConsume"..statType] do
		task.wait(1)
		for _,item in pairs(inventoryList:GetChildren()) do
			if item:FindFirstChild("ItemName") and item:FindFirstChild("ID") then
				local itemName=item.ItemName.Text
				if potionLists[statType][itemName] then
					local id=tonumber(item.ID.Value)
					if id then pcall(function()equipRemote:FireServer(id)end) task.wait(0.1) end
				end
			end
		end
	end
end
local function TConsumePower(on)cfg.AutoConsumePower=on;save();getgenv().AutoConsumePower=on;if on then task.spawn(function()consumePotion("Power")end)end end
local function TConsumeHealth(on)cfg.AutoConsumeHealth=on;save();getgenv().AutoConsumeHealth=on;if on then task.spawn(function()consumePotion("Health")end)end end
local function TConsumeDefense(on)cfg.AutoConsumeDefense=on;save();getgenv().AutoConsumeDefense=on;if on then task.spawn(function()consumePotion("Defense")end)end end
local function TConsumePsychic(on)cfg.AutoConsumePsychic=on;save();getgenv().AutoConsumePsychic=on;if on then task.spawn(function()consumePotion("Psychic")end)end end
local function TConsumeMagic(on)cfg.AutoConsumeMagic=on;save();getgenv().AutoConsumeMagic=on;if on then task.spawn(function()consumePotion("Magic")end)end end
local function TConsumeMobility(on)cfg.AutoConsumeMobility=on;save();getgenv().AutoConsumeMobility=on;if on then task.spawn(function()consumePotion("Mobility")end)end end
local function TConsumeSuper(on)cfg.AutoConsumeSuper=on;save();getgenv().AutoConsumeSuper=on;if on then task.spawn(function()consumePotion("Super")end)end end

local C1=Section(CScroll,'Mob FireBall Aimbot')
Toggle(C1,'Universal FireBall Aimbot','UniversalFireBallAimbot',UFA);Slider(C1,'Universal Fireball Cooldown','universalFireballInterval',0.05,1.0,1.0,function()end)

--- Custom Mob Order UI for Universal Fireball
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Custom Mob Order (Click mobs to add to sequence)',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},C1)

-- Current order display
local OrderLabel = mk('TextLabel',{Size=UDim2.new(1,-12,0,40),BackgroundTransparency=1,Text='Current Order: None',TextColor3=Color3.fromRGB(200,200,200),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.Gotham,TextWrapped=true},C1)

local function updateOrderDisplay()
	if cfg.UFAOrderedMobs and #cfg.UFAOrderedMobs > 0 then
		OrderLabel.Text = 'Current Order: ' .. table.concat(cfg.UFAOrderedMobs, ' → ')
	else
		OrderLabel.Text = 'Current Order: None'
	end
end

-- Clear order button
local ClearBtn = mk('TextButton',{Size=UDim2.new(0,120,0,28),BackgroundColor3=Color3.fromRGB(180,50,50),BorderSizePixel=0,Text='Clear Order',TextColor3=Color3.fromRGB(255,255,255),TextScaled=true,Font=Enum.Font.Gotham},C1)
mk('UICorner',{CornerRadius=UDim.new(0,6)},ClearBtn)
ClearBtn.MouseButton1Click:Connect(function()
	cfg.UFAOrderedMobs = {}
	updateOrderDisplay()
	save()
end)

-- Mob selection grid (2 columns, click to add to order)
local MobGrid = mk('Frame',{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},C1)
local GridLayout = Instance.new('UIGridLayout')
GridLayout.Parent = MobGrid
GridLayout.CellPadding = UDim2.new(0,8,0,8)
GridLayout.CellSize = UDim2.new(0.5,-6,0,32)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makeMobButton(name)
	local b = Instance.new('TextButton')
	b.Name = 'Mob_' .. name
	b.Size = UDim2.new(0,0,0,32)
	b.BackgroundColor3 = Color3.fromRGB(36,36,48)
	b.BorderSizePixel = 0
	b.Text = name
	b.TextColor3 = Color3.fromRGB(235,235,245)
	b.TextScaled = true
	b.Font = Enum.Font.Gotham
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0,8)
	corner.Parent = b
	b.Parent = MobGrid
	
	b.MouseButton1Click:Connect(function()
		-- Add to ordered list if not already present
		if not table.find(cfg.UFAOrderedMobs, name) then
			table.insert(cfg.UFAOrderedMobs, name)
			updateOrderDisplay()
		save()
		end
	end)
	
	-- Visual feedback on hover
	b.MouseEnter:Connect(function()
		if not table.find(cfg.UFAOrderedMobs, name) then
			b.BackgroundColor3 = Color3.fromRGB(50,50,60)
		end
	end)
	b.MouseLeave:Connect(function()
		if not table.find(cfg.UFAOrderedMobs, name) then
			b.BackgroundColor3 = Color3.fromRGB(36,36,48)
		end
	end)
end

-- Create mob buttons
do 
	local names = uniqueMobNames() 
	for _, name in ipairs(names) do 
		makeMobButton(name) 
	end 
end

-- Initialize display
updateOrderDisplay()

Toggle(C1,'FireBall Aimbot Catacombs Preset','FireBallAimbot',CatAimbot);Slider(C1,'Fireball Cooldown','fireballCooldown',0.05,1.0,0.1,function()end)
Toggle(C1,'FireBall Aimbot City Preset','FireBallAimbotCity',CityAimbot);Slider(C1,'City Fireball Cooldown','cityFireballCooldown',0.05,1.0,0.5,function()end)
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Panic',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},C1)
Toggle(C1,'Smart Panic','SmartPanic',function(on)cfg.SmartPanic=on;getgenv().SmartPanic=on;save()end)
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Pvp',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},C1)
Toggle(C1,'Kill Aura','KillAura',TKA)
Toggle(C1,'Gamma Ray Aimbot (g key)','GammaAimbot',TGamma)
Toggle(C1,'Auto Block','AutoBlock',TAutoBlock)
Toggle(C1,'Combat Log','CombatLog',TCombatLog)

local M1=Section(Move,'Movement Features')
Toggle(M1,'No Clip','NoClip',TNoClip)
Toggle(M1,'Infinite Zoom','InfiniteZoom',TInfiniteZoom)

local U1=Section(UScroll,'Utility Features')
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Optimizations',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},U1)
Toggle(U1,'Ultimate AFK Optimization','UltimateAFKOptimization',TUltimate)
Toggle(U1,'AFK Optimization','GraphicsOptimization',TAFK)
Toggle(U1,'Graphics Optimization','GraphicsOptimizationAdvanced',TGfxAdv)
Toggle(U1,'Remove Map Clutter','RemoveMapClutter',function(on)if on then RemoveClutter()end end)
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Webhooks',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},U1)
Toggle(U1,'Death Webhook','DeathWebhook',function(on)cfg.DeathWebhook=on;save()end)
Toggle(U1,'Panic Webhook','PanicWebhook',function(on)cfg.PanicWebhook=on;save()end)
Toggle(U1,'Stat Webhook (15m)','StatWebhook15m',TStatWH)
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Security',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},U1)
Toggle(U1,'Kick On Untrusted Players','KickOnUntrustedPlayers',TKickUntrusted)
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Auto Ability',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},U1)
Toggle(U1,'Auto Invisible','AutoInvisible',TInv);Toggle(U1,'Auto Resize','AutoResize',TResize);Toggle(U1,'Auto Fly','AutoFly',TFly)
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Guis',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},U1)
Toggle(U1,'Quick Teleport Gui','QuickTeleports',TQuickTeleports)

local V1=Section(Visual,'Visual Features')
Toggle(V1,'Player ESP','PlayerESP',TPlayerESP)
Toggle(V1,'Mob ESP','MobESP',TMobESP)

local Q1=Section(Quests,'Quest Automation')
Toggle(Q1,'Dishes Side Task','AutoWashDishes',TWash)
Toggle(Q1,'Ninja Side Task','AutoNinjaSideTask',TNinja)
Toggle(Q1,'Animatronics Side Task','AutoAnimatronicsSideTask',TAnim)
Toggle(Q1,'Mutants Side Task','AutoMutantsSideTask',TMut)

local S1=Section(Shops,'Shop Automation')
Toggle(S1,'Dual Exotic Shop','DualExoticShop',TDualExotic)
Toggle(S1,'Vending Machine','VendingPotionAutoBuy',TVend)

local H1=Section(HealthT,'Health Exploit')
mk('TextLabel',{Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,Text='Health Exploit',TextColor3=Color3.fromRGB(235,235,245),TextXAlignment=Enum.TextXAlignment.Left,TextScaled=true,Font=Enum.Font.GothamBold},H1)
Toggle(H1,'Health Exploit','HealthExploit',THealthExploit)

local P1=Section(Potions,'Auto Consume')
Toggle(P1,'Consume Power','AutoConsumePower',TConsumePower)
Toggle(P1,'Consume Health','AutoConsumeHealth',TConsumeHealth)
Toggle(P1,'Consume Defense','AutoConsumeDefense',TConsumeDefense)
Toggle(P1,'Consume Psychic','AutoConsumePsychic',TConsumePsychic)
Toggle(P1,'Consume Magic','AutoConsumeMagic',TConsumeMagic)
Toggle(P1,'Consume Mobility','AutoConsumeMobility',TConsumeMobility)
Toggle(P1,'Consume Super','AutoConsumeSuper',TConsumeSuper)
local Cfg=Section(Conf,'Configuration')
local SB=Btn(Cfg,'Save Config',function()save()end)
local LB=Btn(Cfg,'Load Config',function()
	load()
	local function ap(flag,get,tgl) if get() ~= flag then tgl(flag) end end
	ap(cfg.NoClip,function()return getgenv().NoClip or false end,TNoClip)
	ap(cfg.GraphicsOptimization,function()return getgenv().GraphicsOptimization or false end,TAFK)
	ap(cfg.GraphicsOptimizationAdvanced,function()return getgenv().GraphicsOptimizationAdvanced or false end,TGfxAdv)
	ap(cfg.UltimateAFKOptimization,function()return cfg.UltimateAFKOptimization end,TUltimate)
	ap(cfg.PlayerESP,function()return getgenv().PlayerESP or false end,TPlayerESP)
	ap(cfg.UniversalFireBallAimbot,function()return getgenv().UniversalFireBallAimbot or false end,UFA)
	ap(cfg.FireBallAimbot,function()return getgenv().FireBallAimbot or false end,CatAimbot)
	ap(cfg.FireBallAimbotCity,function()return getgenv().FireBallAimbotCity or false end,CityAimbot)
	ap(cfg.AutoWashDishes,function()return getgenv().AutoWashDishes or false end,TWash)
	ap(cfg.AutoNinjaSideTask,function()return getgenv().AutoNinjaSideTask or false end,TNinja)
	ap(cfg.AutoAnimatronicsSideTask,function()return getgenv().AutoAnimatronicsSideTask or false end,TAnim)
	ap(cfg.AutoMutantsSideTask,function()return getgenv().AutoMutantsSideTask or false end,TMut)
	ap(cfg.DualExoticShop,function()return getgenv().DualExoticShop or false end,TDualExotic)
	ap(cfg.VendingPotionAutoBuy,function()return getgenv().VendingPotionAutoBuy or false end,TVend)
	ap(cfg.StatWebhook15m,function()return getgenv().StatWebhook15m or false end,TStatWH)
	ap(cfg.KillAura,function()return getgenv().KillAura or false end,TKA)
	ap(cfg.QuickTeleports,function()return getgenv().QuickTeleports or false end,TQuickTeleports)
	ap(cfg.AutoInvisible,function()return getgenv().AutoInvisible or false end,TInv)
	ap(cfg.AutoResize,function()return getgenv().AutoResize or false end,TResize)
	ap(cfg.AutoFly,function()return getgenv().AutoFly or false end,TFly)
	ap(cfg.HealthExploit,function()return getgenv().HealthExploit or false end,THealthExploit)
	ap(cfg.GammaAimbot,function()return getgenv().GammaAimbot or false end,TGamma)
	ap(cfg.InfiniteZoom,function()return getgenv().InfiniteZoom or false end,TInfiniteZoom)
	ap(cfg.AutoConsumePower,function()return getgenv().AutoConsumePower or false end,TConsumePower)
	ap(cfg.KickOnUntrustedPlayers,function()return getgenv().KickOnUntrustedPlayers or false end,TKickUntrusted)
	ap(cfg.AutoConsumeHealth,function()return getgenv().AutoConsumeHealth or false end,TConsumeHealth)
	ap(cfg.AutoConsumeDefense,function()return getgenv().AutoConsumeDefense or false end,TConsumeDefense)
	ap(cfg.AutoConsumePsychic,function()return getgenv().AutoConsumePsychic or false end,TConsumePsychic)
	ap(cfg.AutoConsumeMagic,function()return getgenv().AutoConsumeMagic or false end,TConsumeMagic)
	ap(cfg.AutoConsumeMobility,function()return getgenv().AutoConsumeMobility or false end,TConsumeMobility)
	ap(cfg.AutoConsumeSuper,function()return getgenv().AutoConsumeSuper or false end,TConsumeSuper)
	ap(cfg.AutoBlock,function()return getgenv().AutoBlock or false end,TAutoBlock)
	ap(cfg.CombatLog,function()return getgenv().CombatLog or false end,TCombatLog)
	getgenv().SmartPanic = cfg.SmartPanic and true or false
end)
SB.Position=UDim2.new(0,0,0,0);LB.Position=UDim2.new(0,270,0,0)
local SHK=Btn(Cfg,"Set Hide Key ("..(cfg.HideGUIKey or'RightControl')..")",function()waitingKey=true;SHK.Text='Press any key...'end);SetHideBtn=SHK;SHK.Position=UDim2.new(0,540,0,0)
