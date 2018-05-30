module BoxalinoPackage
	class BxRequest
		require 'BoxalinoPackage/BxSortFields'
		require 'BoxalinoPackage/p13n_types'
		

	  def initialize(language, choiceId, max=10, min=0)
	    	@language, @groupBy, @choiceId, @min, @max, @withRelaxation , @indexId ,	@requestMap , returnFields = Array.new, @indexId
				@offset = 0
				@queryText = ""
				@bxFacets = nil

				@bxSortFields = nil
				@bxFilters = Array.new
				@orFilters = false
				@hitsGroupsAsHits = nil
				@groupFacets = nil
				@requestContextParameters = Array.new()
				if (choiceId == '')
						raise  'BxRequest created with null choiceId'
				end
				@language = language
				@choiceId = choiceId
				@min = Float(min)
				@max = Float(max)
				if(@max == 0)
						@max = 1
				end
				@withRelaxation = choiceId == 'search'
				@contextItems = Array.new
	    end
		
		def getWithRelaxation

			return @withRelaxation
			
		end

		def setWithRelaxation(withRelaxation)
			@withRelaxation = withRelaxation
		end

		def getReturnFields

			return @returnFields
			
		end

		def setReturnFields(returnFields)
			
			@returnFields  = returnFields 

		end

		def getOffset
			return @offset
		end

		def setOffset(offset)
			@offset = offset
		end
		def getQuerytext
			return @queryText
		end
		def setQuerytext(queryText)
			@queryText = queryText
		end
		def setQueryText(queryText)
			@queryText = queryText
		end
		def getFacets
			return @bxFacets
		end
		def setFacets(bxFacets)
			@bxFacets = bxFacets
		end
		def getSortFields
			return @bxSortFields
		end
		def setSortFields(bxSortFields)
			@bxSortFields =bxSortFields
		end
		def getFilters
			filters  = @bxFilters
			if (getFacets())
				getFacets().getFilters().each do |filter|
					filters.push(filter)
				end			
			end
			return @bxFilters		
		end

		def setFilters(bxFilters)
			@bxFilters = bxFilters
		end

		def addFilter(bxFilter)
			@bxFilters[@bxFilter.getFieldName()] = bxFilter
		end

		def getOrFilters

			return @orFilters
			
		end
		def setOrFilters(orFilters)
			return @orFilters = orFilters
		end
		def addSortField(field, reverse = false)
			if(@bxSortFields == nil) 
				@bxSortFields = BxSortFields.new
			end
			@bxSortFields.push(field, reverse)
		end
		def getChoiceId
			return @choiceId
		end
		def setChoiceId(choiceId)
			@choiceId = choiceId
		end
		def getMax
			return @max
		end
		def setMax(max)
			@max = max
		end
		def getMin
			return @min
		end
		def setMin(min)
			@min = min
		end
		def getIndexId
			return @indexId
		end
		def setIndexId(indexId)
			@indexId = indexId
			if @contextItems != nil
				@contextItems.each do | contextItem, k|
					if contextItem.indexId == nil
						@contextItems[k]['indexId']= indexId
					end
				end
			end
		end

		def setDefaultIndexId(indexId)
			if @indexId== nil
				setIndexId(indexId)
			end
		end
		def setDefaultRequestMap(requestMap)
			if @requestMap == nil
				@requestMap = requestMap
			end
		end
		def getLanguage
			return @language
		end
		def setLanguage(language)
			@language = language
		end
		def getGroupBy
			return @groupBy
		end
		def setGroupBy(groupBy)
			@groupBy = groupBy
		end
		def setHitsGroupsAsHits(groupsAsHits)
			@hitsGroupsAsHits = groupsAsHits
		end
		def setGroupFacets(groupFacets)
			@groupFacets = groupFacets
		end
		def getSimpleSearchQuery
			searchQuery  = SimpleSearchQuery.new()
			searchQuery.indexId = getIndexId()
			searchQuery.language = getLanguage()
			searchQuery.returnFields = getReturnFields()
			searchQuery.offset = getOffset()
			searchQuery.hitCount = getMax()
			searchQuery.queryText = getQueryText()
			searchQuery.groupFacets = (@groupFacets == nil ) ? false : @groupFacets
			searchQuery.groupBy = @groupBy
			if @hitsGroupsAsHits != nil
				searchQuery.hitsGroupsAsHits = @hitsGroupsAsHits
			end
			if getFilters().length >0
				searchQuery.filters = Array.new
				getFilters().each do |filter|
					searchQuery.filters.push(filter.getThriftFilter())
				end
			end
			searchQuery.orFilters = getOrFilters()
			if (getFacets()) 
				searchQuery.facetRequests = getFacets().getThriftFacets()
			end
			if(getSortFields()) 
				searchQuery.sortFields = getSortFields().getThriftSortFields()
			end
			return $searchQuery;
		end

		def setProductContext(fieldName, contextItemId, role = 'mainProduct', relatedProducts = Array.new() , relatedProductField = 'id')
			contextItem = ContextItem.new()
			contextItem.indexId = getIndexId()
			contextItem.fieldName = fieldName
			contextItem.contextItemId = contextItemId
			contextItem.role = role
			@contextItems.push(contextItem)
			addRelatedProducts(relatedProducts, relatedProductField)
		end
		def setBasketProductWithPrices(fieldName, basketContent, role = 'mainProduct', subRole = 'mainProduct', relatedProducts = Array.new() , relatedProductField='id')
			if (basketContent != false && basketContent.length > 0) 
				
				# Sort basket content by price
				basketContent.sort_by { |k| k[:price] }
				basketItem = basketContent.shift
				
				contextItem = ContextItem.new()
				contextItem.indexId = getIndexId()
				contextItem.fieldName = fieldName
				contextItem.contextItemId = basketItem['id']
				contextItem.role = role
				@contextItems.push(contextItem)
				basketContent.each do |basketItem| 
					contextItem = ContextItem.new()
					contextItem.indexId = getIndexId()
					contextItem.fieldName = fieldName
					contextItem.contextItemId = basketItem['id']
					contextItem.role = $subRole
					@contextItems.push(contextItem)
				end
			end
			addRelatedProducts(relatedProducts, relatedProductField)
		end

		def addRelatedProducts(relatedProducts, relatedProductField='id') 
	        if(!relatedProducts.empty?)
						relatedProducts.each do |productId , related|
								key = "bx_{"+@choiceId+"}_"+productId
								@requestContextParameters[key] = related
						end
					end
	    end

	    def getContextItems 
			return @contextItems
		end
		
		def getRequestContextParameters
			return @requestContextParameters
		end
		
		def retrieveHitFieldValues(item, field, items, fields) 
			return Array.new 
		end
	end
end