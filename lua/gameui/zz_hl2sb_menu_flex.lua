if not MENU_DLL then return end

local function ApplyMenuFlex(html)
    html:QueueJavascript([[
        (function() {
            if (location.protocol !== 'asset:' || location.hostname !== 'garrysmod' ||
                location.pathname !== '/html/menu.html' || document.getElementById('hl2sb-menu-flex')) return;
            var style = document.createElement('style');
            style.id = 'hl2sb-menu-flex';
            style.textContent = '#NavBar,#NavBar .group{display:flex}' +
                '#NavBar .group.center{flex:1 1 auto;justify-content:flex-end}' +
                '#NavBar .group.left,#NavBar .group.right{flex:0 0 auto}';
            document.head.appendChild(style);
        })();
    ]])
end

local boundHTML
local nextCheck = 0
hook.Add("Think", "HL2SBMenuLegacyFlex", function()
    if SysTime() < nextCheck then return end
    nextCheck = SysTime() + 1

    local menu = pnlMainMenu
    if not IsValid(menu) or not IsValid(menu.HTML) then
        boundHTML = nil
        return
    end
    local html = menu.HTML
    if html == boundHTML then return end
    boundHTML = html

    local ref = html:GetTable()
    local previousFinish = rawget(ref, "OnFinishLoadingDocument")
    ref.OnFinishLoadingDocument = function(self, url)
        if previousFinish then previousFinish(self, url) end
        if IsValid(self) and IsValid(pnlMainMenu) and pnlMainMenu.HTML == self then
            ApplyMenuFlex(self)
        end
    end
    if not html:IsLoading() then ApplyMenuFlex(html) end
end)
