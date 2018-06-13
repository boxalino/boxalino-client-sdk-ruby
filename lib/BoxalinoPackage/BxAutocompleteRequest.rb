module BoxalinoPackage
	class BxAutocompleteRequest
		require 'BoxalinoPackage/BxSearchRequest'
		require 'BoxalinoPackage/p13n_types'
		@indexId = nil

		def initialize(language, queryText, textualSuggestionsHitCount, productSuggestionHitCount = 5, autocompleteChoiceId = 'autocomplete', searchChoiceId = 'search', highlight = true, highlightPre = '<em>', highlightPost = '</em>')
			@indexId = nil
			@language = language
			@queryText = queryText
			@textualSuggestionsHitCount = textualSuggestionsHitCount
			@highlight = highlight
			@highlightPre = highlightPre
			@highlightPost = highlightPost
			if (autocompleteChoiceId == nil)
				autocompleteChoiceId = 'autocomplete'
			end
			@choiceId = autocompleteChoiceId
			@propertyQueries = Array.new()
			@bxSearchRequest = BxSearchRequest.new(language, queryText, productSuggestionHitCount, searchChoiceId)
		end 

		def getBxSearchRequest() 
			return @bxSearchRequest
		end
		
		def setBxSearchRequest(bxSearchRequest) 
			@bxSearchRequest = bxSearchRequest;
		end

		def getLanguage 
			return @language
		end
		
		def  setLanguage(language) 
			@language = language
		end
		
		def getQuerytext 
			return @queryText
		end
		
		def  setQuerytext(queryText) 
			@queryText = queryText
		end

		def getChoiceId 
			return @choiceId
		end
		
		def setChoiceId(choiceId) 
			@choiceId = choiceId
		end
		
		def getTextualSuggestionHitCount() 
			return @textualSuggestionsHitCount
		end
		
		def setTextualSuggestionHitCount(textualSuggestionsHitCount) 
			@textualSuggestionsHitCount = textualSuggestionsHitCount
		end

		def getIndexId 
			return @indexId
		end
		
		def setIndexId(indexId) 
			@indexId = indexId
		end

		def setDefaultIndexId(indexId) 
			if @indexId == nil
				setIndexId(indexId)
			end
			@bxSearchRequest.setDefaultIndexId(indexId)
		end
		
		def getHighlight 
			return @highlight
		end
		
		def getHighlightPre 
			return @highlightPre
		end
		
		def getHighlightPost() 
			return @highlightPost
		end
		
		def getAutocompleteQuery() 
			autocompleteQuery = AutocompleteQuery.new()
			autocompleteQuery.indexId = getIndexId()
			autocompleteQuery.language = @language
			autocompleteQuery.queryText = @queryText
			autocompleteQuery.suggestionsHitCount = @textualSuggestionsHitCount
			autocompleteQuery.highlight = @highlight
			autocompleteQuery.highlightPre = @highlightPre
			autocompleteQuery.highlightPost = @highlightPost
			return autocompleteQuery
		end

		@propertyQueries = Array.new()

		def addPropertyQuery(field, hitCount, evaluateTotal=false) 
			propertyQuery = PropertyQuery.new()
			propertyQuery.name = field
			propertyQuery.hitCount = hitCount
			propertyQuery.evaluateTotal = evaluateTotal
			@propertyQueries.push(propertyQuery)
		end
		
		def resetPropertyQueries() 
			@propertyQueries = Hash.new()
		end
		
		def getAutocompleteThriftRequest(profileid, thriftUserRecord) 
			autocompleteRequest = AutocompleteRequest.new()
			autocompleteRequest.userRecord = thriftUserRecord
			autocompleteRequest.profileId = profileid
			autocompleteRequest.choiceId = @choiceId
			autocompleteRequest.searchQuery = @bxSearchRequest.getSimpleSearchQuery()
			autocompleteRequest.searchChoiceId = @bxSearchRequest.getChoiceId()
			autocompleteRequest.autocompleteQuery = getAutocompleteQuery()
			if (@propertyQueries.length > 0 )
			#	autocompleteRequest.propertyQueries = @propertyQueries
			end
			return autocompleteRequest
		end
		
		
	end
end