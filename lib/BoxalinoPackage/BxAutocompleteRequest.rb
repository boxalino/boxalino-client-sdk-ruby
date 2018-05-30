module BoxalinoPackage
	class BxAutocompleteRequest
		require 'BoxalinoPackage/BxSearchRequest'
		indexId = nil

		def initialize(language, queryText, textualSuggestionsHitCount, productSuggestionHitCount = 5, autocompleteChoiceId = 'autocomplete', searchChoiceId = 'search', highlight = true, highlightPre = '<em>', highlightPost = '</em>')  
			language = language  
			queryText = queryText
			textualSuggestionsHitCount = textualSuggestionsHitCount
			highlight = highlight
			highlightPre = highlightPre
			highlightPost = highlightPost
			if (autocompleteChoiceId == nil)
				autocompleteChoiceId = 'autocomplete'
			end
			choiceId = autocompleteChoiceId
			bxSearchRequest = BxSearchRequest.new(language, queryText, productSuggestionHitCount, searchChoiceId) 
		end 

		def getBxSearchRequest() 
			return self.bxSearchRequest
		end
		
		def setBxSearchRequest(bxSearchRequest) 
			self.bxSearchRequest = bxSearchRequest;
		end

		def getLanguage 
			return self.language
		end
		
		def  setLanguage(language) 
			self.language = language
		end
		
		def getQuerytext 
			return self.queryText
		end
		
		def  setQuerytext(queryText) 
			self.queryText = queryText
		end

		def getChoiceId 
			return self.choiceId
		end
		
		def setChoiceId(choiceId) 
			self.choiceId = choiceId
		end
		
		def getTextualSuggestionHitCount() 
			return self.textualSuggestionsHitCount
		end
		
		def setTextualSuggestionHitCount(textualSuggestionsHitCount) 
			self.textualSuggestionsHitCount = textualSuggestionsHitCount
		end

		def getIndexId 
			return self.indexId
		end
		
		def setIndexId(indexId) 
			self.indexId = indexId
		end

		def setDefaultIndexId(indexId) 
			if self.indexId == nil 
				setIndexId(indexId)
			end
			self.bxSearchRequest.setDefaultIndexId(indexId)
		end
		
		def getHighlight 
			return self.highlight
		end
		
		def getHighlightPre 
			return self.highlightPre
		end
		
		def getHighlightPost() 
			return self.highlightPost
		end
		
		def getAutocompleteQuery() 
			autocompleteQuery = new AutocompleteQuery()
			autocompleteQuery.indexId = getIndexId()
			autocompleteQuery.language = language
			autocompleteQuery.queryText = queryText
			autocompleteQuery.suggestionsHitCount = textualSuggestionsHitCount
			autocompleteQuery.highlight = highlight
			autocompleteQuery.highlightPre = highlightPre
			autocompleteQuery.highlightPost = highlightPost
			return autocompleteQuery
		end

		propertyQueries = Array.new() 

		def addPropertyQuery(field, hitCount, evaluateTotal=false) 
			propertyQuery = new PropertyQuery()
			propertyQuery.name = field
			propertyQuery.hitCount = hitCount
			propertyQuery.evaluateTotal = evaluateTotal
			propertyQueries.push(propertyQuery)
		end
		
		def resetPropertyQueries() 
			self.propertyQueries = Array.new() 
		end
		
		def getAutocompleteThriftRequest(profileid, thriftUserRecord) 
			autocompleteRequest = new AutocompleteRequest()
			autocompleteRequest.userRecord = thriftUserRecord
			autocompleteRequest.profileId = profileid
			autocompleteRequest.choiceId = self.choiceId
			autocompleteRequest.searchQuery = self.bxSearchRequest.getSimpleSearchQuery()
	        autocompleteRequest.searchChoiceId = self.bxSearchRequest.getChoiceId()
			autocompleteRequest.autocompleteQuery = getAutocompleteQuery()
			if (self.propertyQueries.length > 0 ) 
				autocompleteRequest.propertyQueries = self.propertyQueries
			end
			return autocompleteRequest
		end
		
	end
end