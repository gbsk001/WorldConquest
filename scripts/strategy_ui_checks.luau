local function signal()
 local s={};function s:Connect(fn)table.insert(self,fn);return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in ipairs(self)do fn(...)end end;return s
end
local Enum=setmetatable({},{__index=function(_,k)return setmetatable({},{__index=function(_,v)return k..v end})end})
local Color3={fromRGB=function(...)return {...}end,new=function(...)return {...}end}
local Vector2={new=function(x,y)return {X=x,Y=y}end,zero={X=0,Y=0}}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={new=function(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end}
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local TweenInfo={new=function(...)return {...}end}
local task={delay=function(_,fn)end}
local objects={}
local Instance={new=function(class)
 local props={ClassName=class,Visible=true,AbsoluteSize=Vector2.new(1000,700),AbsolutePosition=Vector2.zero,Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(0,0),Activated=signal(),MouseEnter=signal(),MouseLeave=signal(),Destroying=signal()};local signals={};local object={}
 local attributes={}
 function props:SetAttribute(k,v)attributes[k]=v end
 function props:GetAttribute(k)return attributes[k]end
 function props:GetPropertyChangedSignal(k)signals[k]=signals[k] or signal();return signals[k]end
 function props:IsA(k)return class==k or k=="GuiObject" and (class=="Frame" or class=="ScrollingFrame" or class=="TextButton" or class=="TextLabel")end
 function props:GetDescendants()local out={};for _,o in ipairs(objects)do local p=o.Parent;while p do if p==object then table.insert(out,o);break end;p=p.Parent end end;return out end
 function props:GetChildren()local out={};for _,o in ipairs(objects)do if o.Parent==object then table.insert(out,o)end end;return out end
 function props:Destroy()object.Parent=nil end
 function props:FindFirstChild(name)for _,o in ipairs(objects)do if o.Parent==object and o.Name==name then return o end end end
 function props:FindFirstChildOfClass(k)for _,o in ipairs(objects)do if o.Parent==object and o.ClassName==k then return o end end end
 setmetatable(object,{__index=props,__newindex=function(_,k,v)local old=props[k];props[k]=v;if old~=v and signals[k] then signals[k]:Fire()end end});table.insert(objects,object);return object
end}
local input={InputBegan=signal()}
local game={GetService=function(_,name)if name=="UserInputService" then return input end;if name=="TweenService" then return {Create=function(_,obj,_,values)return {Cancel=function()end,Play=function()for k,v in pairs(values)do obj[k]=v end end}end}end;return {}end}
