--!strict
-- Cloud translations are optional and must never block the main menu.
-- Falls back to authored English; does not filter or accept user-authored text.
local Strings=require(game:GetService("ReplicatedStorage").Shared.LocaleStrings)
local Localisation={}
function Localisation.new(player,root,changed)
 local translator=nil;local cache={};local api={};local live=true;local connection=nil
 local preferred=player:GetAttribute("WCLanguage")or "auto"
 local locale=if preferred=="auto"then game:GetService("LocalizationService").RobloxLocaleId or "en-us"else preferred
 function api.text(source)
  local bundled,known=Strings.translate(source,locale);if known then return bundled end
  if not translator then return source end
  if cache[source]then return cache[source]end
  local ok,value=pcall(function()return translator:Translate(root,source)end)
  local result=if ok then value else source
  -- Bounded cache: dynamic balances/usernames must not accumulate indefinitely.
  if #source<240 then if api.Count and api.Count>=256 then table.clear(cache);api.Count=0 end;cache[source]=result;api.Count=(api.Count or 0)+1 end
  return result
 end
 task.spawn(function()
  local ok,value=pcall(function()local service=game:GetService("LocalizationService");return if preferred=="auto"then service:GetTranslatorForPlayerAsync(player)else service:GetTranslatorForLocaleAsync(locale)end)
  if ok and value and live then
   translator=value;if preferred=="auto"then locale=translator.LocaleId or locale end;table.clear(cache);api.Count=0;changed()
   connection=translator:GetPropertyChangedSignal("LocaleId"):Connect(function()if preferred=="auto"then locale=translator.LocaleId or locale end;table.clear(cache);api.Count=0;changed()end)
  end
 end)
 function api.destroy()live=false;if connection then connection:Disconnect()end end
 return api
end
return Localisation
