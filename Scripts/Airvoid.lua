Voids = class( nil )
Voids.maxParentCount = 1
Voids.maxChildCount = 1
Voids.connectionInput = sm.interactable.connectionType.logic
Voids.connectionOutput = sm.interactable.connectionType.logic
Voids.colorNormal = sm.color.new( 0x844040ff )
Voids.colorHighlight = sm.color.new( 0xb25959ff )
Void = {}
local Voidt = {}
local function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end
local function player_num (tab, val)
  local num = 1
  for index, value in ipairs(tab) do
    if value == val then
      return num
    else
      num = num + 1
    end
  end
end

function Voids.server_onCreate( self )
  self:server_init()
end

function Voids.server_init( self )
  self.lastPosition = nil
end

function Voids.server_onRefresh( self )
  self:server_init()
end

function Voids.server_onFixedUpdate( self, tick )
  if _G.Endall == nil then
    local mainpos = sm.shape.getLocalPosition(self.shape)

    for k, child in pairs(self.interactable:getChildren()) do
      if child then
        local childshape = sm.interactable.getShape(child)
        self.childpos = sm.shape.getLocalPosition(childshape)
        local normalPositionaldifference = (self.childpos - mainpos)
        self.Positional_difference = sm.vec3.new(math.abs(normalPositionaldifference.x),math.abs(normalPositionaldifference.y),math.abs(normalPositionaldifference.z))
        print(mainpos, " shape local position")
		print(self.shape.worldPosition, " shape world position")
        for k, player in pairs(sm.player.getAllPlayers( )) do
		print(player.character:getWorldPosition(), " player world position")
          print(self.shape:transformPoint(player.character:getWorldPosition()), " returned player position")
          print(self.shape:transformPoint(player.character:getWorldPosition()) + mainpos)
          local added_value = ((self.shape:transformPoint(player.character:getWorldPosition()) - mainpos)+(self.shape:transformPoint(player.character.worldPosition) - self.childpos))
          local abs_added_value = sm.vec3.new(math.abs(added_value.x),math.abs(added_value.y),math.abs(added_value.z))
          if has_value (Voidt, player) then

            if abs_added_value > self.Positional_difference then
              local Pnumt = player_num (Voidt, player)
              table.remove(Voidt, Pnumt)
              local Pnum = player_num (Void, player)
              table.remove(Void, Pnum)
            end

          else
            if abs_added_value < self.Positional_difference then
              table.insert(Voidt, player)
              table.insert(Void, player)
            end
          end
        end
      end
    end
  end
end

function Voids.server_onDestroy(self)
  Void = nil
end
function Voids.client_onCreate( self )
end
function Voids.client_onUpdate( self, tick )
end

