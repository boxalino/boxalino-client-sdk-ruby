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
		suggestions = Hash.new
		if(!getResponse().hits.nil?)
			getResponse().hits.each  do |hit|
				if(suggestions.any?)
					if(suggestions[hit.suggestion])
						next
					end
				end
				suggestions[hit.suggestion] = hit.suggestion
			end
		end
		return reOrderSuggestions(suggestions)
	end

	def suggestionIsInGroup(groupName, suggestion)
		hit = getTextualSuggestionHit(suggestion)
		case groupName
		when 'highlighted-beginning'
			if (!hit.highlighted.nil?)
				if( hit.highlighted.index(@bxAutocompleteRequest.getHighlightPre()) == nil)
					return true
				end
			else
				return false
			end

		when 'highlighted-not-beginning'
			if (!hit.highlighted.nil?)
				if(hit.highlighted.index(@bxAutocompleteRequest.getHighlightPre()) != nil)
					return true
				end
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
		queryText = getSearchRequest().getQuerytext()

		groupNames = ['highlighted-beginning', 'highlighted-not-beginning', 'others']
		groupValues = Hash.new
		k = 0
		groupNames.each do | groupName|
			if(!groupValues.empty?)
				if (!groupValues.key?(k))
					groupValues[k] = Hash.new
				end
			else
				groupValues[k] = Hash.new
			end
			if(!suggestions.nil?)
				suggestionGroup = Array.new
				suggestions.each do |suggestion|
					if (suggestionIsInGroup(groupName, suggestion))
						suggestionGroup.push(suggestion)
					end
				end
				groupValues[k] = suggestionGroup
			end
			k +=1
		end

		final = Array.new
		groupValues.each do |values|
			if !values.nil?  && !values[1].nil?
				values[1].each do |value|
					final.push(value)
				end
			end
		end

		return final
	end

	def getTextualSuggestionHit(suggestion)
		if(!getResponse().hits.empty?)
			getResponse().hits.each do |hit|
				if (hit.suggestion == suggestion[0])
					return hit
				end
			end
		end
		raise "unexisting textual suggestion provided " + suggestion.to_s
	end

	def getTextualSuggestionTotalHitCount(suggestion)
		hit = getTextualSuggestionHit(suggestion)
		return hit.searchResult.totalHitCount
	end

	def getSearchRequest
		return @bxAutocompleteRequest.getBxSearchRequest()
	end

	def getTextualSuggestionFacets(suggestion)
		hit = getTextualSuggestionHit(suggestion)

		facets = getSearchRequest().getFacets()

		if (facets.nil? || facets == "" )
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
		searchResult = textualSuggestion.nil? ? getResponse().prefixSearchResult : getTextualSuggestionHit(textualSuggestion).searchResult
		return BxChooseResponse.new(searchResult, @bxAutocompleteRequest.getBxSearchRequest())
	end

	def getPropertyHits(field)
		if(!getResponse().propertyResults.nil? || !getResponse().propertyResults.empty?)
			getResponse().propertyResults.each do |propertyResult|
				if (propertyResult.name == field)
					return propertyResult.hits
				end
			end
		end
		return Array.new
	end

	def getPropertyHit(field, hitValue)
		if(!getPropertyHits(field).nil? || !getPropertyHits(field).empty?)
			getPropertyHits(field).each do |hit|
				if (hit.value == hitValue)
					return hit
				end
			end
		end
		return nil
	end

	def getPropertyHitValues(field)
		hitValues = Array.new
		if(!getPropertyHits(field).nil? || !getPropertyHits(field).empty?)
			getPropertyHits(field).each do |hit|
				hitValues.push(hit.value)
			end
		end
		return hitValues
	end

	def getPropertyHitValueLabel(field, hitValue)
		hit = getPropertyHit(field, hitValue)
		if (!hit.nil?)
			return hit.label
		end
		return nil
	end

	def getPropertyHitValueTotalHitCount(field, hitValue)
		hit = getPropertyHit(field, hitValue)
		if (!hit.nil?)
			return hit.totalHitCount
		end
		return nil
	end

end