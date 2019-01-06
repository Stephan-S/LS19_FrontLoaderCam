





FrontLoaderCam = {};
FrontLoaderCam = {};
FrontLoaderCam.Version = "1.0.0";
FrontLoaderCam.config_changed = false;
FrontLoaderCam.actions             = { 'FrontLoaderCam_Toggle', 'FrontLoaderCam_MoveCam'}
FrontLoaderCam.ViewActions             = { 'AXIS_LOOK_UPDOWN_VEHICLE', 'AXIS_LOOK_LEFTRIGHT_VEHICLE', 'AXIS_MOVE_FORWARD_PLAYER'}


FrontLoaderCam.directory = g_currentModDirectory;


function FrontLoaderCam:prerequisitesPresent(specializations)
    return true;
end;

function FrontLoaderCam:delete()	

end;

function FrontLoaderCam:loadMap(name)		
end;

function FrontLoaderCam.registerEventListeners(vehicleType)
  --print("-> registerEventListeners ")
    
  for _,n in pairs( { "onUpdate", "onRegisterActionEvents" } ) do
    SpecializationUtil.registerEventListener(vehicleType, n, FrontLoaderCam)
  end 
end

function FrontLoaderCam:deleteMap()	
end;

function FrontLoaderCam:load(xmlFile)	
end;

function FrontLoaderCam:onRegisterActionEvents(isSelected, isOnActiveVehicle)  
  -- continue on client side only
  if not self.isClient then
    return
  end
  
  -- only in active vehicle
  if isOnActiveVehicle then
    -- we could have more than one event, so prepare a table to store them  
    if self.ActionEvents == nil then 
      self.ActionEvents = {}
    else  
      self:clearActionEventsTable( self.ActionEvents )
    end 
	
	local frontLoaderDetected = false;
	local attacherJoints = self:getAttacherJoints();
	if attacherJoints ~= nil then
		for _, attcherJointIter in pairs(attacherJoints) do
			--print("jointType: " .. attcherJointIter.jointType);
			if attcherJointIter.jointType == AttacherJoints.JOINTTYPE_ATTACHABLEFRONTLOADER or attcherJointIter.jointType == 9 or attcherJointIter.jointType == 5 or attcherJointIter.jointType == 14 or attcherJointIter.jointType == 4 or attcherJointIter.jointType == 10 then
				frontLoaderDetected = true;
			end;
		end;
	end;
    
	if frontLoaderDetected then
		-- attach our actions
		for _ ,actionName in pairs(FrontLoaderCam.actions) do
			local __, eventName
			if isOnActiveVehicle then
				local toggleButton = false;
				if actionName == "FrontLoaderCam_MoveCam" then
					toggleButton = true;
				end;
				__, eventName = InputBinding.registerActionEvent(g_inputBinding, actionName, self, FrontLoaderCam.onActionCall, toggleButton ,true ,false ,true)
			end
			
			if isSelected then
				g_inputBinding.events[eventName].displayPriority = 1
			elseif isOnActiveVehicle then
				g_inputBinding.events[eventName].displayPriority = 3
			end
		end
		
		for _ ,actionName in pairs(FrontLoaderCam.ViewActions) do
			local __, eventName
			if isOnActiveVehicle then
				__, eventName = InputBinding.registerActionEvent(g_inputBinding, actionName, self, FrontLoaderCam.onActionCall, true ,false ,true ,true)
			end		
			g_inputBinding:setActionEventTextVisibility(eventName, false)
		end
	end;	
  end
end

function FrontLoaderCam:onActionCall(actionName, keyStatus, arg4, arg5, arg6)
	if self.lastInputValues == nil then
		self.lastInputValues = {};		
		self.lastInputValues.upDown = 0;
		self.lastInputValues.leftRight = 0;
		self.movingCam = false;
		self.frontLoaderCamOffsetY = 0;
	end;

	if actionName == "FrontLoaderCam_Toggle" then
		if self.flc.cam == false then		
			self.flc.cam = true;
			self.storedCam = getCamera();
			if self.spec_enterable ~= nil then
				if self.spec_enterable.activeCamera ~= nil then
					self.flc.lastCamIndex = self.spec_enterable.camIndex;
					self.spec_enterable.activeCamera:onDeactivate();
					--print("Deactivated camera");					
				end;
			end;			
		else
			self.flc.cam = false;
			self.restoreLastCam = true;			
		end;
	elseif actionName == "FrontLoaderCam_MoveCam" then
		self.movingCam = not self.movingCam;	
	elseif actionName == "AXIS_LOOK_UPDOWN_VEHICLE" then		
		if self.flc.cam == true then
			self.lastInputValues.upDown = keyStatus;
		end;
	elseif actionName == "AXIS_LOOK_LEFTRIGHT_VEHICLE" then		
		if self.flc.cam == true then
			self.lastInputValues.leftRight = keyStatus;
		end;
	elseif actionName == "AXIS_MOVE_FORWARD_PLAYER" then		
		if self.flc.cam == true then
			self.lastInputValues.translateUpDown = keyStatus;
		end;
	end;
end

function FrontLoaderCam:onLeave()
end;

function init(self)	
	self.lastInputValues =  {};
	self.lastInputValues.upDown = 0;
	self.lastInputValues.leftRight = 0;
	self.movingCam = false;
	self.frontLoaderCamOffsetY = 0;	
	
	if self.flc == nil then
		self.flc = {};
	end;
	
	self.storedCam = getCamera();
	self.restoreLastCam = false;
	
	self.moduleInitialized = true;
	self.currentInput = "";

	--if self.frontloaderAttacher ~= nil or self.typeDesc == "telehandler" then
		if self.frontLoaderCam == nil then			
			self.frontLoaderCam = createCamera("frontLoaderCam",  1.4, 0.02, 200);
			local node = self.components[1].node
			local nodeTool = nil;
			
			local attachedImplements
			if self.getAttachedImplements ~= nil then
				attachedImplements = self:getAttachedImplements()
			end
			if attachedImplements ~= nil then
				for _, implement in pairs(attachedImplements) do
					if implement.object ~= nil then
							if implement.object.typeName == "attachableFrontloader" then
								local attacherJoints = implement.object:getAttacherJoints();
								
								if attacherJoints ~= nil then								
									nodeTool = attacherJoints[1].jointTransform;
								end;
							end;
					end;
				end;
			end;
			
			if self.typeDesc == "telehandler" then
				nodeTool = self.attacherJoints[1].jointTransform;
			end;
			if nodeTool == nil then
				nodeTool = node;
			end;

			link(node, self.frontLoaderCam);
			rotate(self.frontLoaderCam,0,-math.pi*0.5,0);

			local xW,yW,zW = getWorldTranslation(node);
			local xTool,yTool,zTool = getWorldTranslation(nodeTool);
			local xCam,yCam,zCam = getWorldTranslation(self.frontLoaderCam);

			self.frontLoaderCamOffsetX = -1.57; 
			self.frontLoaderCamOffsetZ = 0.33; 
			
			local x,y,z = worldToLocal(node,xTool+self.frontLoaderCamOffsetX,yTool+0.75,zTool+self.frontLoaderCamOffsetZ)
			setTranslation(self.frontLoaderCam,x,y,z);
			
			self.flc.cam = false;				
		end;
	--end;
	
	self.trafficVehicle = nil;
end;

function FrontLoaderCam:newMouseEvent(superFunc,posX, posY, isDown, isUp, button)
end;

function FrontLoaderCam:mouseEvent(posX, posY, isDown, isUp, button)	
end; 

function FrontLoaderCam:keyEvent(unicode, sym, modifier, isDown) 	
end; 

function FrontLoaderCam:onUpdate(dt)
	if self.moduleInitialized == nil then
		init(self);
	end;	

	if self.currentInput ~= "" and self.isServer then
		FrontLoaderCam:InputHandling(self, self.currentInput);
	end;	
	
	if self == g_currentMission.controlledVehicle then
		if self.frontLoaderCam ~= nil then		
			if self.flc.cam == true then			
				local node = self.components[1].node
				local nodeTool = node;
				
				local attachedImplements
				if self.getAttachedImplements ~= nil then
					attachedImplements = self:getAttachedImplements()
				end
				if attachedImplements ~= nil then
					for _, implement in pairs(attachedImplements) do
						if implement.object ~= nil then
							if implement.object.typeName == "attachableFrontloader" then
								local attacherJoints = implement.object:getAttacherJoints();
								
								if attacherJoints ~= nil then								
									nodeTool = attacherJoints[1].jointTransform;
								end;
							end;
						end;
					end;
				end;
				if self.typeDesc == "telehandler" then
					nodeTool = self.attacherJoints[1].jointTransform;
				end;
				
				local xW,yW,zW = getWorldTranslation(node);
				local xTool,yTool,zTool = getWorldTranslation(node);
				local xCam,yCam,zCam = getWorldTranslation(self.frontLoaderCam);
				
				if nodeTool == nil then
					nodeTool = node;
					self.frontLoaderCamOffsetX = self.sizeWidth/2; -- + 0.8;
					self.frontLoaderCamOffsetZ = self.sizeLength/2 + 1.0; -- -1.0
				else
					xTool,yTool,zTool = getWorldTranslation(nodeTool);
				end;
				
				local x,y,z = worldToLocal(node,xTool,yTool+0,zTool)
				
				pitch, yaw, roll = getRotation(self.frontLoaderCam);
			
				if self.lastInputValues.upDown ~= 0 then
					if self.movingCam == false then
						local value = self.lastInputValues.upDown * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY) * 0.075;
						pitch = pitch - value;
						self.lastInputValues.upDown = 0;
					else
						local value = self.lastInputValues.upDown * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY) * 0.075;

						self.frontLoaderCamOffsetZ = self.frontLoaderCamOffsetZ + math.cos(yaw)*value;
						self.frontLoaderCamOffsetX = self.frontLoaderCamOffsetX + math.sin(yaw)*value;						
						
						self.lastInputValues.upDown = 0;
					end;
				end;
				
				if self.lastInputValues.leftRight ~= 0 then
					if self.movingCam == false then
						local value = self.lastInputValues.leftRight * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY) * 0.075;
						yaw = yaw - value;
						self.lastInputValues.leftRight = 0;
					else
						local value = self.lastInputValues.leftRight * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY) * 0.075;
						
						self.frontLoaderCamOffsetX = self.frontLoaderCamOffsetX + math.cos(yaw)*value;
						self.frontLoaderCamOffsetZ = self.frontLoaderCamOffsetZ - math.sin(yaw)*value;
						
						self.lastInputValues.leftRight = 0;
					end;
				end;
				
				if self.lastInputValues.translateUpDown ~= 0 then
					if self.movingCam == false then
						self.lastInputValues.translateUpDown = 0;
					else
						local value = self.lastInputValues.translateUpDown * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY) * 0.075;
						
						self.frontLoaderCamOffsetY = self.frontLoaderCamOffsetY - value;
						
						self.lastInputValues.translateUpDown = 0;
					end;
				end;
				
				self.frontLoaderCamOffsetX = MathUtil.clamp(-10, self.frontLoaderCamOffsetX, 10);
				self.frontLoaderCamOffsetY = MathUtil.clamp(-10, self.frontLoaderCamOffsetY, 10);
				self.frontLoaderCamOffsetZ = MathUtil.clamp(-10, self.frontLoaderCamOffsetZ, 10);
				
				setTranslation(self.frontLoaderCam,x+self.frontLoaderCamOffsetX,y + self.frontLoaderCamOffsetY, z+self.frontLoaderCamOffsetZ);				
				setRotation(self.frontLoaderCam, pitch, yaw, roll);
				
				setCamera(self.frontLoaderCam);
			else
				if (self.restoreLastCam == true) then
					self.restoreLastCam = false;
					setCamera(self.storedCam);
					if self.spec_enterable ~= nil then
						if self.flc.lastCamIndex ~= nil then
							self.spec_enterable:setActiveCameraIndex(self.flc.lastCamIndex);
							--print("Activated camera");					
						end;
					end;	
				end;			
			end;
		end;
	end;
end;

function createVector(x,y,z)
	local table t = {};
	t["x"] = x;
	t["y"] = y;
	t["z"] = z;
	return t; 
end;

function getDistance(x1,z1,x2,z2)
	return math.sqrt((x1-x2)*(x1-x2) + (z1-z2)*(z1-z2) );
end;

function FrontLoaderCam:draw()
end; 

function round(num, idp) 
	if Utils.getNoNil(num, 0) > 0 then 
		local mult = 10^(idp or 0); 
		return math.floor(num * mult + 0.5) / mult; 
	else 
		return 0; 
	end; 
end; 

function getPercentage(capacity, level) 
	return level / capacity * 100; 
end;

function FrontLoaderCam:angleBetween(vec1, vec2)

	local scalarproduct_top = vec1.x * vec2.x + vec1.z * vec2.z;
	local scalarproduct_down = math.sqrt(vec1.x * vec1.x + vec1.z*vec1.z) * math.sqrt(vec2.x * vec2.x + vec2.z*vec2.z)
	local scalarproduct = scalarproduct_top / scalarproduct_down;

	return math.deg(math.acos(scalarproduct));
end

function mySelf(obj)
  return " (rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end

function bool_to_number(value)
  return value and 1 or 0
end

addModEventListener(FrontLoaderCam);
