module BoxalinoPackage
    require 'json'
    class BxChooseResponse
        
        def initialize(response, bxRequests=Array.new) 
            @response = response
            @bxRequests = bxRequests.kind_of?(Array) ? bxRequests : Array.new(bxRequests)
        end

        @notificationLog = Array.new

        @notificationMode = false

        def setNotificationMode(mode) 
            @notificationMode = mode;
            @bxRequests.each do |bxRequest|
                facet = bxRequest.getFacets()
                if(facet != nil) 
                    facet.setNotificationMode(mode)
                end
            end
        end

        def getNotificationMode
            @notificationMode
        end

        def addNotification(nname, parameters) 
            if(@notificationMode) 
                @notifications.push(Hash.new({'name'=>nname, 'parameters'=>parameters}))
            end
        end

        def getNotifications
            finalNotifications = @notifications
            @bxRequests.each do |bxRequest|
                finalNotifications.push(Hash.new({'name' => 'bxFacet', 'parameters' => bxRequest.getChoiceId()}))
                bxRequest.getFacets().getNotifications().each do |notification|
                    finalNotifications.push(notification)
                end
            end
            return finalNotifications
        end

        def getResponse
            return @response
        end

        def getChoiceResponseVariant(choice=nil, count=0) 

            @bxRequests.each do |k , bxRequest|
                if (choice == nil || choice == bxRequest.getChoiceId()) 
                    if (count > 0)
                        count -= 1
                        next
                    end
                    return getChoiceIdResponseVariant(k)
                end
            end
        end

        def getChoiceIdResponseVariant(id=0) 
            response = getResponse();
            if ( response.variants !=''  && response.variants.key?(id)) 
                return response.variants[id]
            end
            #autocompletion case (no variants)
            if(response.class.name == 'SearchResult') 
                variant = Variant.new()
                variant.searchResult = response
                return variant
            end
            raise "no variant provided in choice response for variant id $id, bxRequest: " + pp(@bxRequests)
        end

        def getFirstPositiveSuggestionSearchResult(variant, maxDistance=10) 
            if(variant.searchRelaxation.suggestionsResults == nil) 
                return nil
            end
            variant.searchRelaxation.suggestionsResults.each do |searchResult|
                if (searchResult.totalHitCount > 0) 
                    if(searchResult.queryText == "" || variant.searchResult.queryText == "") 
                        next
                    end
                    distance = levenshtein_distance(searchResult.queryText, variant.searchResult.queryText)
                    if(distance <= maxDistance && distance != -1) 
                        return searchResult
                    end
                end
            end
            return nil
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

        def getVariantSearchResult(variant, considerRelaxation=true, maxDistance=10, discardIfSubPhrases = true) 

            searchResult = variant.searchResult
            if(considerRelaxation && variant.searchResult.totalHitCount == 0 && !(discardIfSubPhrases && areThereSubPhrases())) 
               correctedResult = getFirstPositiveSuggestionSearchResult(variant, maxDistance)
            end
            return correctedResult == nil ? correctedResult : searchResult
        end
        
        def getSearchResultHitVariable(searchResult, hitId, field) 
            if(searchResult) 
                if(searchResult.hits) 
                    searchResult.hits.each do |item|
                        if(item.values['id'] == hitId) 
                            return item.field
                        end
                    end
                elsif(searchResult.hitsGroups != nil) 
                    searchResult.hitsGroups do |hitGroup|
                        if(hitGroup.groupValue == hitId) 
                            return hitGroup.hits[0].field
                        end
                    end
                end
            end
            return nil
        end
        
        def getSearchResultHitFieldValue(searchResult, hitId, fieldName='')

            if (searchResult && fieldName != '') 
                if(searchResult.hits) 
                    searchResult.hits.each do |item|
                        if(item.values['id'] == hitId) 
                            return item.values[fieldName] ? item.values[fieldName][0] : nil
                        end
                    end
                elsif( searchResult.hitsGroups) 
                    searchResult.hitsGroups.each do |hitGroup|
                        if(hitGroup.groupValue == hitId) 
                            return hitGroup.hits[0].values[fieldName] ? hitGroup.hits[0].values[fieldName][0] : nil
                        end
                    end
                end
            end
            return nil
        end
        
        def getSearchResultHitIds(searchResult, fieldId='id') 
            ids = Array.new
            if(searchResult) 
                if(searchResult.hits)
                    searchResult.hits.each do |item|
                        if( item.values[fieldId][0] == nil) 
                            fieldId = 'id'
                        end
                        ids.push(item.values[fieldId][0])
                    end
                elsif (searchResult.hitsGroups)
                    searchResult.hitsGroups.each do |hitGroup|
                        ids.push(hitGroup.groupValue)
                    end
                end
            end
            return ids
        end

        def getHitExtraInfo(choice=nil,hitId = 0, info_key='', default_value = '', count=0, considerRelaxation=true, maxDistance=10, discardIfSubPhrases = true) 
            variant = getChoiceResponseVariant(choice, count)
            extraInfo = getSearchResultHitVariable(getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases), hitId, 'extraInfo')
            return extraInfo.key[info_key] ? extraInfo[info_key] : (default_value != '' ? default_value :  nil)
        end
        
        def getHitVariable(choice=nil, hitId = 0, field='',  count=0, considerRelaxation=true, maxDistance=10, discardIfSubPhrases = true)
            variant = getChoiceResponseVariant(choice, count)
            return getSearchResultHitVariable(getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases), hitId, field)
        end
        
        def getHitFieldValue(choice=null, hitId = 0,  fieldName='',  count=0, considerRelaxation=true, maxDistance=10, discardIfSubPhrases = true)
            variant = getChoiceResponseVariant(choice, count)
            return getSearchResultHitFieldValue(getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases), hitId, fieldName)
        end

        def getHitIds(choice=nil, considerRelaxation=true, count=0, maxDistance=10, fieldId='id', discardIfSubPhrases = true) 
            variant = getChoiceResponseVariant(choice, count)
            return getSearchResultHitIds(getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases), fieldId)
        end

        def retrieveHitFieldValues(item, field, fields, hits) 
            fieldValues = Array.new
            bxRequests.each do |bxRequest|
                fieldValues = fieldValues.merge(bxRequest.retrieveHitFieldValues(item, field, fields, hits))
            end
            return fieldValues
        end

        def getSearchHitFieldValues(searchResult, fields=nil) 
            fieldValues = Array.new
            if(searchResult) 
                hits = searchResult.hits
                if(searchResult.hits == nil)
                    hits = Array.new
                    if(searchResult.hitsGroups != nil) 
                        searchResult.hitsGroups.each do |hitGroup|
                            hits.push(hitGroup.hits[0])
                        end
                    end
                end
                hits.each do |item|
                    finalFields = fields
                    if(finalFields == nil) 
                        finalFields = item.values.keys
                    end
                    finalFields.each do |field|
                        if (item.values[field] != nil) 
                            if (item.values[field] != "") 
                                fieldValues[item.values['id'][0]][field] = item.values[field]
                            end
                        end
                        if( fieldValues[item.values['id'][0]][field] == nil ) 
                            fieldValues[item.values['id'][0]][field] = retrieveHitFieldValues(item, field, searchResult.hits, finalFields)
                        end
                    end
                end
            end
            return fieldValues
        end

        def getRequestFacets(choice=nil) 
            if( choice == nil) 
                if(@bxRequests[0] != nil) 
                    return @bxRequests[0].getFacets()
                end
                return nil
            end
            @bxRequests.each do |bxRequest|
                if (@bxRequest.getChoiceId() == choice) 
                    return @bxRequest.getFacets()
                end
            end
            return nil
        end

        def getFacets(choice=nil, considerRelaxation=true, count=0,maxDistance=10, discardIfSubPhrases = true) 

            variant = getChoiceResponseVariant(choice, count)
            searchResult = getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases)
            facets = getRequestFacets(choice)

            if(facets =="" || searchResult == nil)
                return BxFacets.new()
            end
            facets.setSearchResults(searchResult)
            return facets
        end

        def getHitFieldValues(fields, choice=nil, considerRelaxation=true, count=0,maxDistance=10, discardIfSubPhrases = true) 
            variant = getChoiceResponseVariant(choice, count)
            return getSearchHitFieldValues(getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases), fields)
        end

        def getFirstHitFieldValue(field=nil, returnOneValue=true, hitIndex=0,choice=nil, count=0, maxDistance=10) 
            fieldNames = nil
            if(field != nil) 
                fieldNames = Array.new(field)
            end
            count = 0
            getHitFieldValues(fieldNames, choice, true, count, maxDistance).each do |id , fieldValueMap|
                count += 1
                if ( count < hitIndex) 
                    next
                end
                fieldValueMap.each do |fieldName , fieldValues|
                    if(fieldValues.size > 0 ) 
                        if(returnOneValue) 
                            return fieldValues[0]
                        else 
                            return fieldValues
                        end
                    end
                end
            end
            return nil
        end

        def getTotalHitCount(choice=nil, considerRelaxation=true,count=0, maxDistance=10, discardIfSubPhrases = true) 
            variant = getChoiceResponseVariant(choice, count)
            searchResult = getVariantSearchResult(variant, considerRelaxation, maxDistance, discardIfSubPhrases)
            if($searchResult == nil) 
                return 0;
            end
            return searchResult.totalHitCount
        end

        def areResultsCorrected(choice=null, count=0, maxDistance=10)
            return getTotalHitCount(choice, false, count) == 0 && getTotalHitCount(choice, true, count, maxDistance) > 0 && areThereSubPhrases() == false
        end

        def areResultsCorrectedAndAlsoProvideSubPhrases(choice=nil, count=0, maxDistance=10) 
            return getTotalHitCount(choice, false, count) == 0 && getTotalHitCount(choice, true, count, maxDistance, false) > 0 && areThereSubPhrases() == true
        end

        def getCorrectedQuery(choice=nil, count=0, maxDistance=10) 
            variant = getChoiceResponseVariant(choice, count)
            searchResult = getVariantSearchResult(variant, true, maxDistance, false)
            if(searchResult) 
                return searchResult.queryText
            end
            return nil
        end

        def getResultTitle(choice=nil, count=0, default='- no title -') 

            variant = getChoiceResponseVariant(choice, count)
            if(variant.searchResultTitle) 
                return variant.searchResultTitle
            end
            return default
        end

        def areThereSubPhrases(choice=nil, count=0, maxBaseResults=0) 
            variant = getChoiceResponseVariant(choice, count)
            return variant.searchRelaxation.subphrasesResults != nil && variant.searchRelaxation.subphrasesResults.size > 0 && getTotalHitCount(choice, false, count) <= maxBaseResults
        end

        def getSubPhrasesQueries(choice=nil, count=0) 
            if(!areThereSubPhrases(choice, count)) 
                return Array.new
            end
            queries = Array.new
            variant = getChoiceResponseVariant(choice, count)
            variant.searchRelaxation.subphrasesResults.each do |searchResult|
                queries.push(searchResult.queryText)
            end
            return queries
        end

        def getSubPhraseSearchResult(queryText, choice=nil, count=0) 
            if(!areThereSubPhrases(choice, count)) 
                return nil
            end
            variant = getChoiceResponseVariant(choice, count)
            variant.searchRelaxation.subphrasesResults.each do |searchResult|
                if(searchResult.queryText == queryText) 
                    return searchResult
                end
            end
            return nil
        end

        def getSubPhraseTotalHitCount(queryText, choice=nil, count=0) 
            searchResult = getSubPhraseSearchResult(queryText, choice, count)
            if(searchResult) 
                return searchResult.totalHitCount
            end
            return 0
        end

        def getSubPhraseHitIds(queryText, choice=nil, count=0, fieldId='id') 
            searchResult = getSubPhraseSearchResult(queryText, choice, count)
            if(searchResult) 
                return getSearchResultHitIds(searchResult, fieldId)
            end
            return Array.new
        end

        def getSubPhraseHitFieldValues(queryText, fields, choice=nil, considerRelaxation=true, count=0) 
            searchResult = getSubPhraseSearchResult(queryText, choice, count)
            if(searchResult) 
                return getSearchHitFieldValues(searchResult, fields)
            end
            return Array.new
        end

        def toJson(fields) 
            object = Array.new
            object['hits'] = Array.new
            getHitFieldValues(fields).each do |id , fieldValueMap|
                hitFieldValues = Array.new
                fieldValueMap.each do |fieldName , fieldValues|
                    hitFieldValues[fieldName] = Array.new('values'=>fieldValues)
                end
                object['hits'].push(Array.new('id'=>id, 'fieldValues'=>hitFieldValues))
            end
            return object.to_json
        end

        def getSearchResultExtraInfo(searchResult, extraInfoKey, defaultExtraInfoValue = nil) 
            if(searchResult) 
                if(searchResult.extraInfo.kind_of?(Array) && searchResult.extraInfo.size > 0 && searchResult.extraInfo.keys[extraInfoKey]) 
                    return searchResult.extraInfo[extraInfoKey]
                end
                return defaultExtraInfoValue
            end
            return defaultExtraInfoValue
        end

        def getVariantExtraInfo(variant, extraInfoKey, defaultExtraInfoValue = nil) 
            if(variant) 
                if(variant.extraInfo.kind_of?(Array) && variant.extraInfo.size > 0 && variant.extraInfo.keys[extraInfoKey]) 
                    return variant.extraInfo[extraInfoKey]
                end
                return defaultExtraInfoValue
            end
            return defaultExtraInfoValue
        end

        def getExtraInfo(extraInfoKey, defaultExtraInfoValue = nil, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 

            variant = getChoiceResponseVariant(choice, count)

            return getVariantExtraInfo(variant, extraInfoKey)
        end

        def prettyPrintLabel(label, prettyPrint=false) 
            if(prettyPrint) 
                label['_'] = " "
                label['products'] = ""
                label = label.strip
                label = label[0,1].upcase
            end
            return label
        end

        def getLanguage(defaultLanguage = 'en') 
            if(@bxRequests[0]) 
                return @bxRequests[0].getLanguage()
            end
            return defaultLanguage
        end

        def getExtraInfoLocalizedValue(extraInfoKey, language=nil, defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            jsonLabel = getExtraInfo(extraInfoKey, defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases, defaultValue=nil)
            if(jsonLabel == nil) 
                return prettyPrintLabel(defaultValue, prettyPrint)
            end
            labels = ActiveSupport::JSON.decode(jsonLabel)
            if(language == nil) 
                language = getLanguage()
            end
            if(!labels.kind_of?(Array)) 
                return jsonLabel
            end
            labels.each do |label|
                if(language && label.language != language) 
                    next
                end
                if(label.value != nil) 
                    return prettyPrintLabel(label.value, prettyPrint)
                end
            end
            return prettyPrintLabel(defaultValue, prettyPrint)
        end

        def getSearchMessageTitle(language=nil, defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfoLocalizedValue('search_message_title',language, defaultExtraInfoValue, prettyPrint, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageDescription(language=nil, defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfoLocalizedValue('search_message_description', language, defaultExtraInfoValue, prettyPrint, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageTitleStyle(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_title_style', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageDescriptionStyle(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_description_style', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageContainerStyle(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_container_style', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageLinkStyle(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_link_style', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageSideImageStyle(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_side_image_style', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageMainImageStyle(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_main_image_style', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageMainImage(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_main_image', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageSideImage(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_side_image', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageLink(language=nil, defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfoLocalizedValue('search_message_link', language, defaultExtraInfoValue, prettyPrint, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getRedirectLink(language=nil, defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfoLocalizedValue('redirect_url', language, defaultExtraInfoValue, prettyPrint, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageGeneralCss(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_general_css', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end

        def getSearchMessageDisplayType(defaultExtraInfoValue = nil, prettyPrint=false, choice=nil, considerRelaxation=true, count=0, maxDistance=10, discardIfSubPhrases = true) 
            return getExtraInfo('search_message_display_type', defaultExtraInfoValue, choice, considerRelaxation, count, maxDistance, discardIfSubPhrases)
        end 
    end
end