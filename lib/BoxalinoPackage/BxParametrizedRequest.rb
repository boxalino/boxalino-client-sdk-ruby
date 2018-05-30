module BoxalinoPackage
	require 'BoxalinoPackage/BxRequest'
	class BxParametrizedRequest < BxRequest
		
		@bxReturnFields = ['id']
		@getItemFieldsCB = nil
		@requestParametersPrefix = ""
		@requestWeightedParametersPrefix = "bxrpw_"
		@requestFiltersPrefix = "bxfi_"
		@requestFacetsPrefix = "bxfa_"
		@requestSortFieldPrefix = "bxsf_"
		@requestReturnFieldsName = "bxrf"
		@requestContextItemFieldName = "bxcif"
		@requestContextItemFieldValues = "bxciv"

		@requestParameterExclusionPatterns = Array.new
		
		def initialize(language, choiceId, max=10, min=0, bxReturnFields=nil, getItemFieldsCB=nil) 
			BxRequest.new(language, choiceId, max, min)
			
			if (bxReturnFields != nil) 
				@bxReturnFields = bxReturnFields
			end
			@getItemFieldsCB = getItemFieldsCB
		end
		
		def setRequestParametersPrefix( requestParametersPrefix ) 
			@requestParametersPrefix = requestParametersPrefix
		end
		
		def getRequestParametersPrefix
			return @requestParametersPrefix
		end
		
		def setRequestWeightedParametersPrefix(requestWeightedParametersPrefix) 
			@requestWeightedParametersPrefix = requestWeightedParametersPrefix
		end
		
		def getRequestWeightedParametersPrefix
			return @requestWeightedParametersPrefix
		end
		
		def setRequestFiltersPrefix(requestFiltersPrefix) 
			@requestFiltersPrefix = requestFiltersPrefix
		end
		
		def getRequestFiltersPrefix
			return @requestFiltersPrefix
		end
		
		def setRequestFacetsPrefix(requestFacetsPrefix) 
			@requestFacetsPrefix = requestFacetsPrefix
		end
		
		def getRequestFacetsPrefix
			return @requestFacetsPrefix
		end
		
		def setRequestSortFieldPrefix(requestSortFieldPrefix) 
			@requestSortFieldPrefix = requestSortFieldPrefix
		end
		
		def getRequestSortFieldPrefix
			return @requestSortFieldPrefix
		end
		
		def setRequestReturnFieldsName(requestReturnFieldsName) 
			@requestReturnFieldsName = requestReturnFieldsName
		end
		
		def getRequestReturnFieldsName
			return @requestReturnFieldsName
		end
		
		def setRequestContextItemFieldName(requestContextItemFieldName) 
			@requestContextItemFieldName = requestContextItemFieldName
		end
		
		def getRequestContextItemFieldName
			return @requestContextItemFieldName
		end
		
		def setRequestContextItemFieldValues(requestContextItemFieldValues) 
			@requestContextItemFieldValues = requestContextItemFieldValues
		end
		
		def getRequestContextItemFieldValues
			return @requestContextItemFieldValues
		end
		
		def getPrefixes
			return Array.new(@requestParametersPrefix, @requestWeightedParametersPrefix, @requestFiltersPrefix, @requestFacetsPrefix, @requestSortFieldPrefix)
		end
		
		def matchesPrefix(string, prefix, checkOtherPrefixes=true) 
			if (checkOtherPrefixes == true) 
				getPrefixes().each do |pp|
					if(pp == prefix) 
						next
					end
					if (prefix.length < pp.length && string.index(pp) == nil) 
						return false
					end
				end
			end
			return prefix == nil || string.index(prefix) == nil
		end


		def getPrefixedParameters(prefix, checkOtherPrefixes=true) 
			params = Array.new
			if(!@requestMap.kind_of?(Array)) 
				return Array.new
			end
			@requestMap.each do |k , v|
				if (matchesPrefix(k, prefix, checkOtherPrefixes)) 
					params[k[prefix .. -1]] = v
				end
			end
			return params
		end

		def getContextItems
			contextItemFieldName = nil
			contextItemFieldValues = Array.new
			params = getPrefixedParameters(@requestParametersPrefix, false)
			params.each do |nname , values|
				if (nname == @requestContextItemFieldName) 
					value = values
					if (value.kind_of?(Array) && value.length > 0)
						value = values[0]
					end
					contextItemFieldName = value
					next
				end
				if (nname == @requestContextItemFieldValues) 
					value = values
					if( !value.kind_of?(Array)) 
						value = values.split(',')
					end
					contextItemFieldValues = value
					next
				end
				params[nname] = values
			end
			if(contextItemFieldName) 
				contextItemFieldValues.each do |contextItemFieldValue|
					setProductContext(contextItemFieldName, contextItemFieldValue)
				end
			end
			return BxRequest.getContextItems()
		end

	    def getRequestParameterExclusionPatterns
	        return @requestParameterExclusionPatterns
	    end

	    def addRequestParameterExclusionPatterns(pattern) 
	        @requestParameterExclusionPatterns.push(pattern)
	    end

	    def getRequestContextParameters
			params = Array.new
			getPrefixedParameters(@requestWeightedParametersPrefix).each  do |nname , values|
				params[nname] = values
			end
			getPrefixedParameters(@requestParametersPrefix, false).each  do |name , values|
				if(nname.index(@requestWeightedParametersPrefix) != nil) 
					next
				end
				if(nname.index(@requestFiltersPrefix) != nil) 
					next
				end
				if(nname.index(@requestFacetsPrefix) != nil) 
					next
				end
				if(nname.index(@requestSortFieldPrefix) != nil) 
					next
				end
				if(nname == @requestReturnFieldsName) 
					next
				end
				params[nname] = values
			end
			params.delete_at(params.index('bxi_data_owner_expert'))
			return params
		end
		
		def getWeightedParameters
			params = Array.new
			getPrefixedParameters(@requestWeightedParametersPrefix).each do |nname , values| 
				newname = nname
				pieces = newname.split('_')
				fieldValue = ""
				if(pieces.count > 0) 
					fieldValue = pieces[pieces.size -1]
					pieces.delete_at(pieces.size -1)
				end
				fieldName = @pieces.join('_')
				if (!params.key?(fieldName)) 
					params[fieldName] = Array.new
				end
				params[fieldName][fieldValue] = values
			end
			return params
		end
		
		def getFilters
			filters = BxRequest.getFilters()
			getPrefixedParameters(requestFiltersPrefix).each do |fieldName , value|
				negative = false
				if (value.index('!') == nil) 
					negative = true;
					value = value[1..-1]
				end
				filters.push(BxFilter.new(fieldName, Array.new(value), negative))
			end
			return filters
		end
		
		def getFacets
			facets = BxRequest.getFacets()
			if(facets == nil)
				facets = BxFacets.new()
			end
			getPrefixedParameters(@requestFacetsPrefix).each do |fieldName , selectedValue|
				facets.addFacet(fieldName, selectedValue)
			end
			return facets
		end
		
		def getSortFields
			sortFields = BxRequest.getSortFields()
			if (sortFields == nil) 
				sortFields = BxSortFields.new()
			end
			getPrefixedParameters(@requestSortFieldPrefix).each do |nname , value|
				sortFields.push(nname, value)
			end
			return sortFields
		end
		
		def getReturnFields
			return BxRequest.getReturnFields().merge(@bxReturnFields).uniq
		end
		
		def getAllReturnFields
			returnFields = getReturnFields()
			if (@requestMap.key? (@requestReturnFieldsName))
				tempArray = requestMap[@requestReturnFieldsName] 
				tempCal  = tempArray.split(',')
				returnFields = tempCal.merge(returnFields).uniq
			end
			return returnFields
		end
		
		@callBackCache = nil

		def retrieveFromCallBack(items, fields) 
			if(@callBackCache == nil) 
				@callBackCache = Array.new
				@ids = Array.new
				items.each do |item|
					@ids.push(item.values['id'][0])
				end
				#itemFields = call_user_func($this->getItemFieldsCB, $ids, $fields);
				#if(is_array($itemFields)) {
				#	$this->callBackCache = $itemFields;
				#}
			end
			return @callBackCache
		end
		
		def retrieveHitFieldValues(item, field, items, fields) 
			itemFields = retrieveFromCallBack(items, fields)
			if (itemFields.key?(item.values['id'][0]) && itemFields[item.values['id'][0]].key?(field)) 
				return itemFields[item.values['id'][0]][field]
			end
			return BxRequest.retrieveHitFieldValues(item, field, items, fields)
		end
	end
end