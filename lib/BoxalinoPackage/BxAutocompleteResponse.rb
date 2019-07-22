module BoxalinoPackage
	require 'digest'
	class BxAutocompleteResponse
		@response
		@bxAutocompleteRequest
		@textualSuggestions

		def initialize(response, bxAutocompleteRequest=nil)
			@response = response
			@bxAutocompleteRequest = bxAutocompleteRequest
			@textualSuggestions = Array.new
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

		def getTextualSuggestions(maxDistance=0.5)
			if(@textualSuggestions.length > 0)
				return @textualSuggestions
			end
			suggestions = Hash.new
			response = getResponse
			if(!response.hits.nil?)
				response.hits.each  do |hit|
					if(suggestions[hit.suggestion].nil?)
						suggestions[hit.suggestion] = hit.suggestion
					end
				end
			end
			@textualSuggestions = reOrderSuggestions(suggestions, maxDistance)
			return @textualSuggestions
		end

		def suggestionIsInGroup(groupName, suggestion)
			hit = getTextualSuggestionHit(suggestion)
			case groupName
			when 'highlighted-beginning'
				if (!hit.highlighted.nil?)
					if(hit.highlighted.index(@bxAutocompleteRequest.getHighlightPre()) === 0)
						return true
					else
						return false
					end
				end

			when 'highlighted-not-beginning'
				if (!hit.highlighted.nil?)
					if(hit.highlighted.index(@bxAutocompleteRequest.getHighlightPre()) === 0)
						return false
					else
						return true
					end
				end
			else
				if hit.highlighted.nil?
					return true
				else
					return false
				end
			end
		end

		# reorder steps:
		# match position (perfect match or partial match)
		# partial match
		# match levenstein distance on prefix/suffix
		def reOrderSuggestions(suggestions, maxDistance = 0.5)
			queryText = getSearchRequest().getQuerytext()
			groupNames = ['highlighted-beginning', 'highlighted-not-beginning', 'others']
			groupValues = Hash.new
			k = 0
			groupNames.each do |groupName|
				groupValues[k] = Hash.new
				if(!suggestions.nil?)
					suggestionGroup = Array.new
					suggestions.each do |suggestion, suggestionText|
						if (suggestionIsInGroup(groupName, suggestionText))
							suggestionGroup.push(suggestionText)
						end
					end
					groupValues[k] = suggestionGroup
				end
				k +=1
			end

			final = Array.new
			groupValues.each do |order, values|
				if !values.empty? && !values.nil?
					final.push(getRelevanceSuggestion(queryText, values, maxDistance))
				end
			end

			finalValues = Array.new
			final.each do |elements|
				if(elements.length)
					elements.each do |element|
						element.each do |suggestion|
							finalValues.push(suggestion)
						end
					end
				end
			end

			return finalValues
		end


		def getRelevanceSuggestion(queryText, suggestions, maxDistance=0.5)
			relevanceSuggestions = Hash.new {|h,k| h[k] = [] }
			suggestions.each do |value|
				if(value.include?(" "))
					distanceList = Array.new
					value.strip.split(" ").each do |keyword|
						distance = levenshtein_distance(queryText, keyword)
						if((distance <= 2 || distance.to_f/queryText.length.to_f <= maxDistance) && distance != -1)
							distanceList.push(distance)
						end
					end
					if(distanceList.length>0)
						relevanceSuggestions[distanceList.sort.first].push(value)
					end
				else
					distance = levenshtein_distance(queryText, value)
					if((distance <= 2 || distance.to_f/queryText.length.to_f <= maxDistance)  && distance != -1)
						relevanceSuggestions[distance].push(value)
					end
				end
			end

			return relevanceSuggestions.sort.to_h.values
		end

		def levenshtein_distance(s, t)
			m = s.length
			n = t.length
			return m if n == 0
			return n if m == 0
			d = Array.new(m+1) {Array.new(n+1)}

			(0..m).each {|i| d[i][0] = i}
			(0..n).each {|j| d[0][j] = j}
			(1..n).each do |j|
				(1..m).each do |i|
					d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
											d[i-1][j-1]       # no operation required
										else
											[ d[i-1][j]+1,    # deletion
												d[i][j-1]+1,    # insertion
												d[i-1][j-1]+1,  # substitution
											].min
										end
				end
			end
			d[m][n]
		end

		def getTextualSuggestionHit(suggestion)
			if(!getResponse().hits.empty?)
				if(suggestion.is_a?(Array))
					suggestion = suggestion[0]
				end
				getResponse().hits.each do |hit|
					if (hit.suggestion == suggestion)
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
			if(hit.highlighted.nil? || hit.highlighted.empty?)
				return suggestion
			end
			return hit.highlighted
		end

		def getBxSearchResponse(textualSuggestion = nil)
		if(textualSuggestion.nil?)
			searchResult = getResponse().prefixSearchResult
			if(searchResult.totalHitCount==0)
				mainSuggestion = getTextualSuggestions.first
				searchResult = getTextualSuggestionHit(mainSuggestion).searchResult
			end
		else
			searchResult = getTextualSuggestionHit(textualSuggestion).searchResult
		end

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
end