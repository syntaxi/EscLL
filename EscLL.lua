--[[
	LICENCE TODO
]]

--~ Set up the library ~--
local EscLL = {
	_components = {}, --~ All components created ~--
	_entities = {}, --~ All entities created ~--
	_engines = {}, --~ All engines created~--
	_engineCalls = {} --~ Id's for all engines, sorted by call type ~--
}
setmetatable(EscLL, { __call = function(_) return EscLL:new() end }) --> Allow EscLL() <--

--[[
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~* Component Functions *~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
]]

--~ Create a new component ~--
function EscLL:addComponent(name, data, required)
	--~ Check the Component is unique
	assert(not self._components[name], string.format("Invalid component name: '%s' (Component already exists)", name))
	
	--~ Check required components exist ~--
	if required then
		for i, v in pairs(required) do
			assert(self._components[v], string.format("Invalid component required: '%s' (Does not exist)", v))
		end
	end
	--~ Make the component ~--
	self._components[name] = {_data = data, _entities = {}, _required = required}
end

--[[
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~* Entities *~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
]]

--~ Make a new entity ~--
function EscLL:addEntity(...)
	ar = {...}
	--~ Assert we have the right number of arguments ~--
	assert(#ar/2 == math.floor(#ar/2), "Mismatched number of components to attach and data")
	
	--~ Make the entity ~--
	local entity = {_id = #self._entities+1}
	
	for q = 1, #ar, 2 do
		--~ Assert the component exists ~--
		assert(self._components[ar[q]], string.format("Attempted to attach invalid component: '%s' (Does not exist)", ar[q]))
		
		--~ Add the default data ~--
		entity[ar[q]] = self._components[ar[q]]._data
		
		--~ Replace the defaults ~--
		for key, value in pairs(ar[q+1]) do
			entity[ar[q]][key] = value
		end
		
		--~ Record the entity in the components list ~--
		table.insert(self._components[ar[q]]._entities, entity._id)
	end
	--~ Insert the entity into the global record ~--
	table.insert(self._entities, entity)
	
	return entity
end

function EscLL:addComponentsToEntity(id, components)
	--~ Assert that the Components exist --~
	for i, v in pairs(components) do
		assert(self._components[i], string.format("Attempted to attach invalid component: '%s' (Does not exist)", i))
	end
	for component, data in pairs(components) do
		--~ Record the entity in the component ~--
		table.insert(self._components[component]._entities, id)
		
		--~ Add the default data ~--
		self._entities[id][component] = self._components[component]._data

		--~ Update the defaults ~--
		for key, value in pairs(data) do
			self._entities[id][component][key] = value
		end
	end
end

--[[
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~* Engines *~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
]]



function EscLL:registerEvents()
	local all_callbacks = { 'draw', 'errhand', 'update' }
	for k, v in pairs(love.handlers) do
		table.insert(all_callbacks, k)
	end
	registry = {}
	for v, f in ipairs(all_callbacks) do
		if love[f] then
			registry[f] = love[f]
			love[f] = function(...)
				registry[f](...)
				EscLL:process(f, ...)
			end
		end
		self._engineCalls[f] = {}
	end
end

function EscLL:addEngine(components, callbacks)
	--~ Assert that the Components exist --~
	assert(components, "Missing component argument")
	for i, v in pairs(components) do
		assert(self._components[v], string.format("Invalid component added to engine: '%s' (Does not exist)", v))
	end
	engine = {active = true, _components = {}}
	
	--~ Add the callbacks ~--
	for q, v in pairs(callbacks) do
		engine[q] = v or function() end
		table.insert(self._engineCalls[q], #self._engines+1)
	end
	
	--~ Add component list to engine ~--
	for _, component in pairs(components) do
		table.insert(engine._components, component)
	end
	
	--~ Add the engine to the global list
	table.insert(self._engines, engine)
	return self._engines[#self._engines]
end

function EscLL:process(callback, ...)
	--~ Loop through all relevant engines ~--
	for _, id in pairs(self._engineCalls[callback]) do
		--If the engine is active, generate a list of entities ~--
		local engine = self._engines[id]
		if engine.active then
			entities2 = self._entities
			--~ For every component, remove all the non-relevant entities ~--
			for _, component in pairs(engine._components) do
				entities = entities2
				entities2 = {}
				for i, v in pairs(entities) do
					if v[component] then
						entities2[v._id] = v
					end
				end
			end
			for id, entity in pairs(entities2) do
				engine[callback](entity, ...)
			end
		end
	end
end

--[[
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~* Systems *~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
]]

--~ Create a new System ~--
function EscLL:new()
	EscLL:registerEvents()
	local syst = {}
	setmetatable(syst, self)
	self.__index = self
	return syst
end

--~ Return the library ~--
return EscLL