-- main.lua
-- Script de prueba cargado desde GitHub para Roblox Studio.
-- Úsalo solo en tu propia experiencia/juego.

print("Cargado desde GitHub correctamente")

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print(player.Name .. " entró al juego")
end)

for _, player in ipairs(Players:GetPlayers()) do
	print(player.Name .. " ya estaba dentro del juego")
end
