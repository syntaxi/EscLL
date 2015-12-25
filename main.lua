local EscLL = require 'EscLL'

function love.load()
	system = EscLL()
	system:addComponent("Position", {x = 0, y = 0})
	system:addComponent("Rectangle", {width = 10, height = 10}, {"Position"})
	system:addEntity("Rectangle", {}, "Position", {y = 100})
	system:addEntity("Rectangle", {}, "Position", {y = 200})
	function rectEngineupdate(entity, dt)
		entity.Position.x = entity.Position.x + dt
	end
	function rectEnginedraw(entity)
		print(entity._id, entity.Position.y)
		love.graphics.rectangle("fill", entity.Position.x, entity.Position.y, entity.Rectangle.width, entity.Rectangle.height)
	end
	rectEngine = system:addEngine({"Position"}, {update = rectEngineupdate})
	rectEngine = system:addEngine({"Rectangle"}, {draw = rectEnginedraw})
	
end

function love.mousepressed()

end

function love.update(dt)

end

function love.draw()

end