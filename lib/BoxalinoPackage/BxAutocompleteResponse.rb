module BoxalinoPackage
	require 'digest'
	class BxAutocompleteResponse
		@response
		@bxAutocompleteRequest
		
		def initialize(response, bxAutocompleteRequest=nil) 
			@response = response
			@bxAutocompleteRequest = bxAutocompleteRequest
		end
		
		def getResponse
			return @response
		end

	    def getPrefixSearchHash
	        if (getResponse().prefixSearchResult.totalHitCount > 0) 
	            hashcode = Digest::MD5.hexdigest getResponse().prefixSearchResult.queryText
	            return hashcode[ 0, 10]
	        else 
	            return nil
	        end
	    end
		
		def getTextualSuggestions
			suggestions = Array.new()
			getResponse().hits.each  do |hit|
			    if(suggestions.keys[hit.suggestion]) 
					next
				end
				suggestions[hit.suggestion] = hit.suggestion
	        end
			return reOrderSuggestions(suggestions)
		end
		
		def suggestionIsInGroup(groupName, suggestion) 
			hit = getTextualSuggestionHit(suggestion)
			case groupName
			when 'highlighted-beginning'
				if hit.highlighted != "" && hit.highlighted.index(@bxAutocompleteRequest.getHighlightPre()) == nil
					return true
				else
					return false
				end

			when 'highlighted-not-beginning'
				if hit.highlighted != "" && hit.highlighted.index(@bxAutocompleteRequest.getHighlightPre()) != nil
					return true
				else
					return false
				end
			else
				if hit.highlighted == "" 
					return true
				else
					return false
				end
			end
		end
		
		def reOrderSuggestions(suggestions) 
			queryText = getSearchRequest().getQueryText()
			
			groupNames = Array.new('highlighted-beginning', 'highlighted-not-beginning', 'others')
			groupValues = Array.new
			
			groupNames.each do |k , groupName|
				if (!groupValues.has(k)) 
					groupValues[k] = Array.new
				end
				suggestions.each do |suggestion|
					if (suggestionIsInGroup(groupName, suggestion)) 
						groupValues[k].push(suggestion)
					end
				end
			end
			
			final = Array.new
			groupValues.each do |values|
				values.each do |value|
					final.push(value)
				end
			end
			
			return final
		end
		
		def getTextualSuggestionHit(suggestion) 
			getResponse().hits.each do |hit|
				if (hit.suggestion == suggestion) 
					return hit
				end
			end
			raise "unexisting textual suggestion provided " + suggestion
		end
		
		def getTextualSuggestionTotalHitCount(suggestion) 
			hit = getTextualSuggestionHit(suggestion)
			return hit.searchResult.totalHitCount
		end
		
		def getSearchRequest
			return bxAutocompleteRequest.getBxSearchRequest()
		end
		
		def getTextualSuggestionFacets(suggestion) 
			hit = getTextualSuggestionHit(suggestion)
		
			facets = getSearchRequest().getFacets()

			if (facets ==nil || facets =="" )
				return nil
			end
			facets.setSearchResults(hit.searchResult)
			return facets
		end
		
		def getTextualSuggestionHighlighted(suggestion) 
			hit = getTextualSuggestionHit(suggestion)
			if(hit.highlighted == "") 
				return suggestion
			end
			return hit.highlighted
		end
		
		def getBxSearchResponse(textualSuggestion = nil) 
			searchResult = textualSuggestion == nil ? getResponse().prefixSearchResult : getTextualSuggestionHit(textualSuggestion).searchResult
			return BxChooseResponse.new(searchResult, bxAutocompleteRequest.getBxSearchRequest())
		end
		
		def getPropertyHits(field) 
			getResponse().propertyResults.each do |propertyResult|
				if (propertyResult.name == field) 
					return propertyResult.hits
				end
			end
			return Array.new
		end
		
		def getPropertyHit(field, hitValue) 
			getPropertyHits(field).each do |hit|
				if (hit.value == hitValue) 
					return hit
				end
			end
			return nil
		end
		
		def getPropertyHitValues(field) 
			hitValues = Array.new
			getPropertyHits(field).each do |hit|
				hitValues.push(hit.value)
			end
			return hitValues
		end
		
		def getPropertyHitValueLabel(field, hitValue) 
			hit = getPropertyHit(field, hitValue)
			if (hit != nil) 
				return hit.label
			end
			return nil
		end
		
		def getPropertyHitValueTotalHitCount(field, hitValue) 
			hit = getPropertyHit(field, hitValue)
			if (hit != nil) 
				return hit.totalHitCount
			end
			return nil
		end
		
	end
end