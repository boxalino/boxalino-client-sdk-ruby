module BoxalinoPackage
	class BxFilter
		
		def initialize(fieldName, values=Array.new(), negative = false) 
			@fieldName = fieldName
			@values = values
			@negative = negative
			@hierarchyId = nil
			@hierarchy = nil
			@rangeFrom = nil
			@rangeTo = nil
		end
		
		def getFieldName
			return @fieldName
		end
		
		def getValues
			return @values
		end
		
		def isNegative
			return @negative
		end
		
		def getHierarchyId
			return @hierarchyId
		end
		
		def setHierarchyId(hierarchyId) 
			@hierarchyId = hierarchyId
		end
		
		def getHierarchy
			return @hierarchy
		end
		
		def setHierarchy(hierarchy) 
			@hierarchy = hierarchy
		end
		
		def getRangeFrom
			return @rangeFrom
		end
		
		def setRangeFrom(rangeFrom) 
			@rangeFrom = rangeFrom
		end
		
		def getRangeTo
			return @rangeTo
		end
		
		def setRangeTo(rangeTo) 
			@rangeTo = rangeTo
		end
		
		def getThriftFilter
			filter = Filter()
	        filter.fieldName = @fieldName
	        filter.negative = @negative
	        filter.stringValues = @values
			if(@hierarchyId != nil) 
				filter.hierarchyId = @hierarchyId;
			end
			if(@hierarchy != nil) 
				filter.hierarchy = @hierarchy
			end
			if(@rangeFrom != nil) 
				filter.rangeFrom = @rangeFrom
			end
			if(@rangeTo != nil) 
				filter.rangeTo = @rangeTo
			end
	        return filter
		end
	end
end