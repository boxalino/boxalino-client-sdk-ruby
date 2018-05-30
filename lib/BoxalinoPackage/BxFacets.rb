module BoxalinoPackage
    class BxFacets

    	def initialize
    		@facets = Array.new
    	    @searchResult = nil
    	    @selectedPriceValues = nil
    	    @parameterPrefix = ''
    	    @priceFieldName = 'discountedPrice'
    	    @priceRangeMargin = false
    	    @notificationLog = Array.new
    	    @notificationMode = false
            
            @filters = Array.new
        end

        def setNotificationMode(mode) 
            @notificationMode = mode
        end

        def getNotificationMode 
            return @notificationMode
        end

        def addNotification(nname, parameters) 
            if(@notificationMode) 
                @notificationLog.push(Array.new('name'=>nname, 'parameters'=>parameters))
            end
        end

        def getNotifications
            @notificationLog
        end


        def setSearchResults(searchResult) 
            @searchResult = searchResult
        end

        def getCategoryFieldName
            return "categories"
        end


        def getFilters
            return @filters
        end

        def addCategoryFacet(selectedValue=nil, order=2, maxCount=-1, andSelectedValues = false, label=nil) 
            if(selectedValue) 
                addFacet('category_id', selectedValue, 'hierarchical', nil, '1', false, 1, andSelectedValues)
            end
            addFacet(getCategoryFieldName(), nil, 'hierarchical', label, order, false, maxCount)
        end

        def addPriceRangeFacet(selectedValue=nil, order=2, label='Price', fieldName = 'discountedPrice', maxCount=-1) 
            @priceFieldName = fieldName
            addRangedFacet(fieldName, selectedValue, label, order, true, maxCount)
        end

        def addRangedFacet(fieldName, selectedValue=nil, label=nil, order=2, boundsOnly=false, maxCount=-1) 
            addFacet(fieldName, selectedValue, 'ranged', label, order, boundsOnly, maxCount)
        end

        def addFacet(fieldName, selectedValue=nil, type='string', label=nil, order=2, boundsOnly=false, maxCount=-1, andSelectedValues = false) 
            selectedValues = Array.new
            if(selectedValue != nil) 
                selectedValues = selectedValue.kind_of?(Array) ? selectedValue : [selectedValue]
            end
            @facets[fieldName] = Array.new('label'=>label, 'type'=>type, 'order'=>order, 'selectedValues'=>selectedValues, 'boundsOnly'=>boundsOnly, 'maxCount'=>maxCount, 'andSelectedValues' => andSelectedValues)
        end

        def setParameterPrefix(parameterPrefix) 
            @parameterPrefix = parameterPrefix
        end

        def isCategories(fieldName)
            return fieldName.index(getCategoryFieldName()) != false
        end

        def getFacetParameterName(fieldName) 
            @parameterName = fieldName
            if(isCategories(fieldName)) 
                @parameterName = 'category_id'
            end
            return @parameterPrefix + @parameterName
        end

        def getFieldNames
            @fieldNames = Array.new

            if (@searchResult && @facets.size != @searchResult.facetResponses.size) 
                @searchResult.facetResponses.each do |facetResponse|
                    if(! @facets.keys[facetResponse.fieldName]) 
                        @facets[facetResponse.fieldName] = Array.new(
                            'label' => facetResponse.fieldName,
                            'type' => facetResponse.numerical ? 'ranged' : 'list',
                            'order' => @facets.size,
                            'selectedValues' => [],
                            'boundsOnly' => facetResponse.range,
                            'maxCount' => -1
                        )
                    end
                end
            end
            @facets.each do |fieldName , facet|
                @facetResponse = getFacetResponse(fieldName)
                if(facetResponse != nil && (@facetResponse.values.size > 0 || facet['selectedValues'].size > 0)) 
                    fieldNames[fieldName] = Array.new('fieldName'=>fieldName, 'returnedOrder'=> fieldNames.size)
                end
            end

           uasort(fieldNames)
            return fieldNames.keys
        end 

        def  uasort(fieldNames)
            tempArray = fieldNames
            finalArray = Array.new
            tempArray.each do |a,b|
                aValue = getFacetExtraInfo(a['fieldName'], 'order', a['returnedOrder']).to_i

                if(aValue == 0) 
                    aValue =  a['returnedOrder']
                    finalArray.push(a)
                end
                bValue = getFacetExtraInfo(b['fieldName'], 'order', b['returnedOrder']).to_i
                if(bValue == 0) 
                    bValue =  b['returnedOrder']
                    finalArray.push(b)
                end
            end
        end

        def getDisplayFacets(ddisplay, default=false) 
            selectedFacets = Array.new
            getFieldNames().each do |fieldName|
                if(getFacetDisplay(fieldName) == ddisplay || (getFacetDisplay(fieldName) == nil && default)) 
                    selectedFacets.push(fieldName)
                end
            end
            return selectedFacets
        end

        def getFacetExtraInfoFacets(extraInfoKey, extraInfoValue, default=false, returnHidden=false) 
            selectedFacets = Array.new
            getFieldNames().each do |fieldName|
                if(!$eturnHidden && isFacetHidden(fieldName)) 
                    next
                end
                facetValues = getFacetValues(fieldName)
                if (getFacetType(fieldName) != 'ranged' && (getTotalHitCount() > 0 && facetValues.size == 1) && getFacetExtraInfo(fieldName, "limitOneValueCoverage").to_f >= getFacetValueCount(fieldName, facetValues[0]).to_f / getTotalHitCount() ) 
                    next
                end
                if (getFacetExtraInfo(fieldName, extraInfoKey) == extraInfoValue || (getFacetExtraInfo(fieldName, extraInfoKey) == nil && default)) 
                    selectedFacets.push(fieldName)
                end
            end
            return selectedFacets
        end

        def getLeftFacets(returnHidden=false) 
            @leftFacets = getFacetExtraInfoFacets('position', 'left', true, returnHidden)
            addNotification('getLeftFacets', ActiveSupport::JSON.encode(Array.new(returnHidden, leftFacets)))
            return leftFacets
        end

        def getTopFacets(returnHidden=false) 
            return getFacetExtraInfoFacets('position', 'top', false, returnHidden)
        end

        def  getBottomFacets(returnHidden=false) 
            return getFacetExtraInfoFacets('position', 'bottom', false, returnHidden)
        end

        def getRightFacets(returnHidden=false) 
            return getFacetExtraInfoFacets('position', 'right', false, returnHidden)
        end

        def getFacetResponseExtraInfo(facetResponse, extraInfoKey, defaultExtraInfoValue = nil) 
            if(facetResponse) 
                if(facetResponse.extraInfo .kind_of?(Array) && facetResponse.extraInfo.size > 0 && facetResponse.extraInfo.keys[extraInfoKey])
                    return facetResponse.extraInfo[extraInfoKey]
                end
                return defaultExtraInfoValue
            end
            return defaultExtraInfoValue
        end

        def getFacetResponseDisplay(facetResponse, defaultDisplay = 'expanded') 
            if(facetResponse) 
                if(facetResponse.ddisplay) 
                    return facetResponse.ddisplay
                end
                return defaultDisplay
            end
            return defaultDisplay
        end

        def getAllFacetExtraInfo(fieldName)
            extraInfo = nil
            if (fieldName == getCategoryFieldName()) 
                fieldName = 'category_id'
            end
            begin
                facetResponse =  getFacetResponse(fieldName)
                if(facetResponse != nil  && facetResponse.extraInfo.kind_of?(Array) && facetResponse.extraInfo.size > 0) 
                    return facetResponse.extraInfo
                end
            rescue => ex
                return extraInfo
            end
            return extraInfo
        end

        def getFacetExtraInfo(fieldName, extraInfoKey, defaultExtraInfoValue = nil) 
            if (fieldName == getCategoryFieldName()) 
                fieldName = 'category_id';
            end
            begin
                extraInfo = getFacetResponseExtraInfo(getFacetResponse(fieldName), extraInfoKey, defaultExtraInfoValue)
                addNotification('getFacetResponseExtraInfo', ActiveSupport::JSON.encode(Array.new(fieldName,extraInfoKey, defaultExtraInfoValue, extraInfo)))
                return extraInfo
            rescue => ex
                addNotification('Exception - getFacetResponseExtraInfo', ActiveSupport::JSON.encode(Array.new(fieldName, extraInfoKey, defaultExtraInfoValue)))
                return defaultExtraInfoValue
            end
            return defaultExtraInfoValue
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
        
        def getFacetLabel(fieldName, language=nil, defaultValue=nil, prettyPrint=false) 
            if(facets[fieldName]) 
                defaultValue = facets[fieldName]['label']
            end
            if(defaultValue == nil) 
                defaultValue = fieldName
            end
            if(language != nil) 
                jsonLabel = getFacetExtraInfo(fieldName, "label")
                if(jsonLabel == nil) 
                    return prettyPrintLabel(defaultValue, prettyPrint)
                end
                labels = ActiveSupport::JSON.decode(jsonLabel)
                labels.each do |label|
                    if(language && label.language != language) 
                        next
                    end
                    if(label.value != nil) 
                        return prettyPrintLabel(label.value, prettyPrint)
                    end
                end
            end
            return prettyPrintLabel(defaultValue, prettyPrint)
        end

        def showFacetValueCounters(fieldName, defaultValue=true) 
            return getFacetExtraInfo(fieldName, "showCounter", defaultValue ? "true" : "false") != "false"
        end

        def getFacetIcon(fieldName, defaultValue=nil) 
            return getFacetExtraInfo(fieldName, "icon", defaultValue)
        end

        def isFacetExpanded(fieldName, default=true) 
            fieldName = fieldName == getCategoryFieldName() ? 'category_id' : fieldName
            defaultDisplay = default ? 'expanded' : nil
            return getFacetDisplay(fieldName, defaultDisplay) == 'expanded'
        end

        def getHideCoverageThreshold(fieldName, defaultHideCoverageThreshold = 0) 
            defaultHideCoverageThreshold = getFacetExtraInfo(fieldName, "minDisplayCoverage", defaultHideCoverageThreshold)
            return defaultHideCoverageThreshold
        end

        def getTotalHitCount
            return searchResult.totalHitCount
        end

        def getFacetCoverage(fieldName) 
            coverage = 0
            getFacetValues(fieldName).each do |facetValue|
                coverage = coverage + getFacetValueCount(fieldName, facetValue)
            end
            return coverage
        end

        def isFacetHidden(fieldName, defaultHideCoverageThreshold = 0) 
            if(getFacetDisplay(fieldName) == 'hidden') 
                return true
            end
            defaultHideCoverageThreshold = getHideCoverageThreshold(fieldName, defaultHideCoverageThreshold)
            if(defaultHideCoverageThreshold > 0 && getSelectedValues(fieldName).size == 0)
                ratio = getFacetCoverage(fieldName) / getTotalHitCount()
                return ratio.to_f < defaultHideCoverageThreshold.to_f
            end
            return false
        end

        def getFacetDisplay(fieldName, defaultDisplay = 'expanded') 
            if(fieldName == getCategoryFieldName()) 
                fieldName = 'category_id'
            end
            begin
                if(getFacetSelectedValues(fieldName).size > 0) 
                    return 'expanded'
                end
                return getFacetResponseDisplay(getFacetResponse(fieldName), defaultDisplay)
            rescue => ex
                return defaultDisplay
            end
            return defaultDisplay
        end

        def getFacetResponse(fieldName) 
            if(searchResult != nil && searchResult.facetResponses != nil) 
                searchResult.facetResponses.each do |facetResponse| 
                    if(facetResponse.fieldName == fieldName) 
                        return facetResponse
                    end
                end
            end
            return nil
        end

        def getFacetType(fieldName) 
            type = 'string'
            if(@facets.keys[fieldName])
                type = @facets[fieldName]['type']
            end
            return type
        end

        def buildTree(response, parents = Array.new, parentLevel = 0) 
            if(parents.sixe==0) 
                parents = Array.new
                response.each do |node|
                    if(node.hierarchy.size == 1) 
                        parents.push(node)
                    end
                end
                if(parents.size == 1) 
                    parents = parents[0].hierarchy
                elsif (parents.size > 1) 
                    children = Array.new
                    hitCountSum = 0
                    parents.each do |parent|
                        children.push(buildTree(response, parent.hierarchy,  parentLevel))
                        hitCountSum = hitCountSum + children[children.size-1]['node'].hitCount
                    end
                    root = Array.new
                    root['stringValue'] = '0/Root'
                    root['hitCount'] = hitCountSum
                    root['hierarchyId'] = 0
                    root['hierarchy'] = Array.new
                    root['selected'] = false
                    return Array.new('node'=>root, 'children'=>children)
                end
            end
            children = Array.new
            response.each do |node|
                if(node.hierarchy.size == parentLevel + 2) 
                    allTrue = true
                    parents.each do |k , v| 
                        if(node.hierarchy[k] == nil || node.hierarchy[k] != v) 
                            allTrue = false
                        end
                    end
                    if(allTrue == true) 
                        children.push(buildTree(response, node.hierarchy, parentLevel+1))
                    end
                end
            end
            response.each do |node|
                if(node.hierarchy.size == parentLevel + 1) 
                    allTrue = true
                    node.hierarchy do |k , v|
                        if(parents[k] == nil || parents[k] != v) 
                            allTrue = false
                        end
                    end
                    if(allTrue == true) 
                        return Array.new('node'=>node, 'children'=>children)
                    end
                end
            end
            return nil
        end

        def getFirstNodeWithSeveralChildren(tree, minCategoryLevel=0) 
            if(tree['children'].size == 0) 
                return nil
            end
            if(tree['children'].size > 1 && minCategoryLevel <= 0) 
                return tree
            end
            bestTree = tree['children'][0]
            if(tree['children'].size > 1) 
                tree['children'].each do |node|
                    if(node['node'].hitCount > bestTree['node'].hitCount) 
                        bestTree = node
                    end
                end
            end
            return getFirstNodeWithSeveralChildren(bestTree, minCategoryLevel-1)
        end

        def getFacetSelectedValues(fieldName) 
            selectedValues = Array.new
            getFacetKeysValues(fieldName).each do |val| 
                if(val.selected != nil && val.stringValue != nil) 
                    selectedValues.push(val.stringValue.to_s)
                end
            end
            return selectedValues
        end

        def getSelectedTreeNode(tree) 
            selectedCategoryId = nil
            if(@facets['category_id'] != nil)
                selectedCategoryId = @facets['category_id']['selectedValues'][0]
            end
            if(selectedCategoryId == nil) 
                begin
                    values = getFacetSelectedValues('category_id')
                    if(values.size > 0) 
                        selectedCategoryId = values[0]
                    end
                rescue => ex

                end
            end
            if(selectedCategoryId == nil) 
                return tree
            end
            if(tree['node'] != nil)
                return nil
            end
            tempPart = tree['node'].stringValue
            parts = tempPart.split('/')
            
            if(parts[0] == selectedCategoryId) 
                return tree
            end
            tree['children'].each do |node|
                result = getSelectedTreeNode(node)
                if(result != nil) 
                    return result
                end
            end
            return nil
        end

        def getCategoryById(categoryId) 
            facetResponse = getFacetResponse(getCategoryFieldName())
            if(facetResponse != nil)
                facetResponse.values.each do |bxFacet|
                    if(bxFacet.hierarchyId == categoryId) 
                        return categoryId
                    end
                end
            end
            return nil
        end

        @facetKeyValuesCache = Array.new

        def getFacetKeysValues(fieldName, ranking='alphabetical', minCategoryLevel=0) 

            if(@facetKeyValuesCache[fieldName+'_'+minCategoryLevel]) 
                return @facetKeyValuesCache[fieldName+'_'+$minCategoryLevel]
            end
            if(fieldName == "") 
                return Array.new
            end
            if(fieldName == 'category_id') 
                return Array.new
            end
            facetValues = Array.new
            facetResponse = getFacetResponse(fieldName)
            if(facetResponse== nil) 
                return Array.new
            end
            type = getFacetType(fieldName)
            case type
                when 'hierarchical'
                    tree = buildTree(facetResponse.values)
                    tree = getSelectedTreeNode(tree)
                    node = getFirstNodeWithSeveralChildren(tree, minCategoryLevel)
                    if(node) 
                        node['children'].each do |node|
                            facetValues[node['node'].stringValue] = node['node']
                        end
                    end
                when 'ranged'
                    displayRange = ActiveSupport::JSON.decode(getFacetExtraInfo(fieldName, 'bx_displayPriceRange'))
                    facetResponse.values.each do |facetValue|
                        if(displayRange) 
                            facetValue.rangeFromInclusive = displayRange[0] != nil ? displayRange[0] : facetValue.rangeFromInclusive
                            facetValue.rangeToExclusive = displayRange[1] != nil ?  displayRange[1] : facetValue.rangeToExclusive
                        end
                        facetValues[facetValue.rangeFromInclusive + '-' + facetValue.rangeToExclusive] = facetValue
                    end
                else

                    facetResponse.values.each do |facetValue|
                        facetValues[facetValue.stringValue] = facetValue
                    end

                    if(facets[fieldName]['selectedValues'].lind_of?(Array)) 
                        facets[fieldName]['selectedValues'].each do |value|
                            if(facetValues[value] == nil) 
                                newValue = FacetValue.new()
                                newValue.rangeFromInclusive = nil
                                newValue.rangeToExclusive = nil
                                newValue.hierarchyId = nil
                                newValue.hierarchy = nil
                                newValue.stringValue = $value
                                newValue.hitCount = 0
                                newValue.selected = true
                                facetValues[value] = newValue
                            end
                        end
                    end
                end

            overWriteRanking = getFacetExtraInfo(fieldName, "valueorderEnums")
            if(overWriteRanking == "counter") 
                ranking = 'counter'
            end
            if(overWriteRanking == "alphabetical") 
                ranking = 'alphabetical'
            end
            if(ranking == 'counter') 
                uasort(facetValues)
            end

            displaySelectedValues = getFacetExtraInfo(fieldName, "displaySelectedValues")
            if(displaySelectedValues == "only") 
                finalFacetValues = Array.new
                facetValues.each do |k , v|
                    if(v.selected) 
                        finalFacetValues[k] = v
                    end
                end
                facetValues = finalFacetValues=="" ? facetValues : finalFacetValues
            end
            if(displaySelectedValues == "top") 
                finalFacetValues = Array.new
                facetValues.each do |k , v|
                    if(v.selected) 
                        finalFacetValues[k] = v
                    end
                end
                facetValues.each do |k , v|
                    if(!v.selected) 
                        finalFacetValues[k] = v
                    end
                end
                facetValues = finalFacetValues
            end
            facetValues = applyDependencies(fieldName, facetValues)
            enumDisplaySize = getFacetExtraInfo(fieldName, "enumDisplayMaxSize").to_i
            if(enumDisplaySize > 0 && facetValues.size > enumDisplaySize) 
                enumDisplaySizeMin = getFacetExtraInfo(fieldName, "enumDisplaySize").to_i
                if(enumDisplaySizeMin == 0)
                    enumDisplaySizeMin = enumDisplaySize
                end
                finalFacetValues = Array.new
                facetValues.each do |k , v|
                    if(finalFacetValues.size >= enumDisplaySizeMin) 
                        v.hidden = true
                    end
                    finalFacetValues[k] = v
                end
                facetValues = finalFacetValues
            end
            facetKeyValuesCache[fieldName+'_'+minCategoryLevel] = facetValues
            return facetValues
        end

        def applyDependencies(fieldName, values)
            dependencies = ActiveSupport::JSON.decode(getFacetExtraInfo(fieldName, "jsonDependencies"))
            if(dependencies != nil && dependencies!="") 
                dependencies.each do |dependency|
                    if(dependency['values']=="") 
                        next
                    end
                    if(dependency['conditions']=="") 
                        effect = dependency['effect']
                        if(effect['hide'] == 'true')
                            dependency['values'].each do |value|
                                if(values[value] != nil)
                                    values.delete_at(values.index(value))
                                end
                            end
                        elsif (effect['hide'] == '') 
                            temp = Array.new
                            dependency['values'].each do |key , value|
                                if(values[value]!= nil)
                                    temp[value] = values[value]
                                    values.delete_at(values.index(value))
                                end
                            end
                            temp = values[effect['order']] = temp
                            values = Array.new
                            temp.each do |value|
                                values[value.stringValue] = value
                            end
                        end
                    end
                end
            end
            return values
        end

        def getSelectedValues(fieldName) 
            selectedValues = Array.new
            begin
                getFacetValues(fieldName).each do |key|
                    if(isFacetValueSelected(fieldName, key)) 
                        selectedValues.push(key)
                    end
                end
            rescue Exception => e
                if(@facets[fieldName]['selectedValues']) 
                    return @facets[fieldName]['selectedValues']
                end
                
            end
            return selectedValues
        end

        def getFacetByFieldName(fieldName) 
            facets.each do |fn , facet|
                if(fieldName == fn) 
                    return facet
                end
            end
            return nil
        end

        def isSelected(fieldName, ignoreCategories=false) 
            if(fieldName == "") 
                return false
            end
            if(isCategories(fieldName)) 
                if(ignoreCategories) 
                    return false
                end
            end
            if(getSelectedValues(fieldName).size > 0) 
                return true
            end
            facet = getFacetByFieldName(fieldName)
            if(facet != nil) 
                if(facet['type'] == 'hierarchical') 
                    facetResponse = getFacetResponse(fieldName)
                    if(facetResponse == nil) 
                       return false
                    end
                    tree = buildTree(facetResponse.values)
                    tree = getSelectedTreeNode(tree)
                    return tree && tree['node'].hierarchy.size > 1
                end
                return @facets[fieldName]['selectedValues'] && @facets[fieldName]['selectedValues'].size > 0
            end
            return false
        end

        def getTreeParent(tree, treeEnd) 
            tree['children'].each do |child| 
                if(child['node'].stringValue == treeEnd['node'].stringValue) 
                    return tree
                end
                parent = getTreeParent(child, treeEnd)
                if(parent) 
                    return parent
                end
            end
            return nil
        end

        def getParentCategories
            fieldName = getCategoryFieldName()
            facetResponse = getFacetResponse(fieldName)
            if(facetResponse == nil) 
               return Array.new
            end
            tree = buildTree(facetResponse.values)
            treeEnd = getSelectedTreeNode(tree)
            if(treeEnd == nil) 
                return Array.new
            end
            if(treeEnd['node'].stringValue == tree['node'].stringValue) 
                return Array.new
            end
            parents = Array.new
            parent = treeEnd
            while parent do
                temp = parent['node'].stringValue
                parts = temp.split('/')
                if(parts[0] != 0) 
                    parents.push(Array.new(parts[0], parts[parts.size-1]))
                end
                parent = getTreeParent(tree, parent)
            end
            parents.sort_by! { |h| }
            final = Array.new
            parents.each do |v| 
                final[v[0]] = v[1]
            end
            return final
        end

        def getParentCategoriesHitCount(id)
            fieldName = getCategoryFieldName()
            facetResponse = getFacetResponse(fieldName)
            if(facetResponse == nil) 
                return 0
            end
            tree = buildTree(@facetResponse.values)
            treeEnd = getSelectedTreeNode(tree)
            if(treeEnd == nil) 
                return tree['node'].hitCount
            end
            if(treeEnd['node'].stringValue == tree['node'].stringValue) 
                return tree['node'].hitCount
            end
            parent = treeEnd
            while parent do
                if(parent['node'].hierarchyId == id)
                    return parent['node'].hitCount
                end
                parent = getTreeParent(tree, parent)
            end
            return 0
        end

        def getSelectedValueLabel(fieldName, iindex=0) 
            if(fieldName == "") 
                return ""
            end
            svs = getSelectedValues(fieldName)
            if(svs[iindex] != nil) 
                return getFacetValueLabel(fieldName, svs[iindex])
            end
            facet = getFacetByFieldName(fieldName)
            if(facet != nil) 
                if(facet['type'] == 'hierarchical') 
                    facetResponse = getFacetResponse(fieldName)
                    if(facetResponse == nil) 
                        return ''
                    end
                    tree = buildTree(facetResponse.values)
                    tree = getSelectedTreeNode(tree)
                    tem = tree['node'].stringValue
                    parts = tem.spit('/')
                    return parts[parts.size-1]
                end
                if(facet['type'] == 'ranged') 
                    if(facets[fieldName]['selectedValues'][0] != nil) 
                        return facets[fieldName]['selectedValues'][0]
                    end
                end
                if(facet['selectedValues'][0] != nil) 
                    return facet['selectedValues'][0]
                end
                return ""
            end
            return ""
        end

        def getPriceFieldName
            return @priceFieldName
        end

        def getCategoriesKeyLabels
            categoryValueArray = Array.new
            getCategories().each do |v|
                label = getCategoryValueLabel(v)
                categoryValueArray[label] = v
            end
            return categoryValueArray
        end

        def getCategoryIdsFromLevel(level) 
            facetResponse = getFacetResponse(getCategoryFieldName())
            ids = Array.new
            if(facetResponse != nil) 
                facetResponse.values do |category|
                    if(category.hierarchy.size == level + 2)
                        ids.push(category.hierarchyId)
                    end
                end
            end
            return ids
        end

        def getCategoryFromLevel(level) 
            facetResponse = getFacetResponse(getCategoryFieldName())
            categories = Array.new
            if(facetResponse != nil) 
                facetResponse.values.each do |category| 
                    if(category.hierarchy.size == level + 2)
                        categories.push(category.stringValue)
                    end
                end
            end
            return categories
        end

        def getSelectedCategoryIds
            ids = Array.new
            if (facets['category_id'])
                ids = facets['category_id']['selectedValues']
            end
            return ids
        end

        def getCategories(ranking='alphabetical', minCategoryLevel=0) 
            return getFacetValues(getCategoryFieldName(), ranking, minCategoryLevel)
        end

        def getPriceRanges
            return getFacetValues(getPriceFieldName())
        end

        @lastSetMinCategoryLevel = 0
        def getFacetValues(fieldName, ranking='alphabetical', minCategoryLevel=0) 
            lastSetMinCategoryLevel = minCategoryLevel
            return getFacetKeysValues(fieldName, ranking, minCategoryLevel).keys
        end

        @@facetValueArrayCache = Array.new
        
        def getFacetValueArray(fieldName, facetValue)
            hhash = fieldName + ' - ' + facetValue
            if(@facetValueArrayCache[hhash]) 
                return @facetValueArrayCache[hhash]
            end
            keyValues = getFacetKeysValues(fieldName, 'alphabetical', @lastSetMinCategoryLevel)
            if( fieldName == @priceFieldName && selectedPriceValues != nil ) 
                fv = keyValues
                from = selectedPriceValues[0].rangeFromInclusive.round(2)
                to = selectedPriceValues[0].rangeToExclusive
                if(priceRangeMargin) 
                    to = to - 0.01
                end
                to = to.round(2)
                valueLabel = from + ' - ' + to
                paramValue = "#{from}-#{to}"
                @facetValueArrayCache[hhash] = Array.new(valueLabel, paramValue, fv.hitCount, true, false)
                return @facetValueArrayCache[hhash]
            end
            if(facetValue.kind_of?(Array))
                facetValue = facetValue
            end
            if(keyValues[facetValue] == nil && fieldName == getCategoryFieldName()) 
                facetResponse = getFacetResponse(getCategoryFieldName())
                if(facetResponse != nil)
                    facetResponse.values.each do |bxFacet| 
                        if(bxFacet.hierarchyId == facetValue) 
                            keyValues[facetValue] = bxFacet
                        end
                    end
                end
            end
            if(keyValues[facetValue] == nil) 
                temp =keyValues.keys.join(',')
                raise "Requesting an invalid facet values for fieldname: " + fieldName + ", requested value: " + facetValue + ", available values . " + temp
            end

            type = getFacetType(fieldName)
            fv = keyValues[facetValue]!= nil ? keyValues[facetValue] : nil
            hidden = fv.hidden != nil ? fv.hidden : false
            case type
                when 'hierarchical'
                    temp = fv.stringValue
                    parts = temp.split("/")
                    facetValueArrayCache[hhash] =  Array.new(parts[parts.size-1], parts[0], fv.hitCount, fv.selected, hidden)
                    return facetValueArrayCache[hhash]
                when 'ranged'
                    from = fv.rangeFromInclusive.round(2)
                    to = fv.rangeToExclusive.round(2)
                    valueLabel = from + ' - ' + to
                    paramValue = fv.stringValue
                    paramValue = "#{from}-#{to}"
                    facetValueArrayCache[hhash] =  Array.new(valueLabel, paramValue, fv.hitCount, fv.selected, hidden)
                    return facetValueArrayCache[hhash]

                else
                    fv = keyValues[facetValue]
                    facetValueArrayCache[hhash] =  Array.new(fv.stringValue, fv.stringValue, fv.hitCount, fv.selected, hidden)
                    return facetValueArrayCache[hhash]
            end
        end

        def getCategoryValueLabel(facetValue)
            return getFacetValueLabel(getCategoryFieldName(), facetValue)
        end

        def getSelectedPriceRange
            valueLabel = nil
            if(@selectedPriceValues != nil )
                from = @selectedPriceValues[0].rangeFromInclusive.round(2)
                to = @selectedPriceValues[0].rangeToExclusive
                if(@priceRangeMargin) 
                    to = to - 0.01
                end
                to = to.round(2)
                valueLabel = from + '-' +to
            end
            return valueLabel
        end

        def getPriceValueLabel(facetValue) 
            return getFacetValueLabel(getPriceFieldName(), facetValue)
        end

        def getFacetValueLabel(fieldName, facetValue) 
            label = getFacetValueArray(fieldName, facetValue)[0]
            parameterValue =getFacetValueArray(fieldName, facetValue)[1]
            hitCount =getFacetValueArray(fieldName, facetValue)[2]
            selected = getFacetValueArray(fieldName, facetValue)[3]
            return label
        end

        def getCategoryValueCount(facetValue)
            return getFacetValueCount(getCategoryFieldName(), facetValue)
        end

        def getPriceValueCount(facetValue) 
            return getFacetValueCount(getPriceFieldName(), facetValue)
        end

        def getFacetValueCount(fieldName,facetValue) 
            label = getFacetValueArray(fieldName, facetValue)[0]
            parameterValue  = getFacetValueArray(fieldName, facetValue)[1]
            hitCount = getFacetValueArray(fieldName, facetValue)[2]
            selected = getFacetValueArray(fieldName, facetValue)[3]
            return hitCount
        end

        def isFacetValueHidden(fieldName, facetValue) 
            label = getFacetValueArray(fieldName, facetValue)[0]
            parameterValue = getFacetValueArray(fieldName, facetValue)[1]
            hitCount = getFacetValueArray(fieldName, facetValue)[2]
            selected = getFacetValueArray(fieldName, facetValue)[3]
            hidden = getFacetValueArray(fieldName, facetValue)[4]
            return hidden
        end

        def getCategoryValueId(facetValue) 
            return getFacetValueParameterValue(getCategoryFieldName(), facetValue)
        end

        def getPriceValueParameterValue(facetValue) 
            return getFacetValueParameterValue(getPriceFieldName(), facetValue)
        end

        def getFacetValueParameterValue(fieldName, facetValue) 
            label =getFacetValueArray(fieldName, facetValue)[0]
            parameterValue = getFacetValueArray(fieldName, facetValue)[1]
            hitCount =getFacetValueArray(fieldName, facetValue)[2]
            selected = getFacetValueArray(fieldName, facetValue)[3]
            return parameterValue
        end

        def isPriceValueSelected(facetValue) 
            return isFacetValueSelected(getPriceFieldName(), facetValue)
        end

        def isFacetValueSelected(fieldName, facetValue) 
            label = getFacetValueArray(fieldName, facetValue)[0]
            parameterValue = getFacetValueArray(fieldName, facetValue)[1]
            hitCount = getFacetValueArray(fieldName, facetValue)[2]
            selected = getFacetValueArray(fieldName, facetValue)[3]
            return selected
        end

        def getFacetValueIcon(fieldName, facetValue,language = nil, defaultValue = '') 
            facetValue = facetValue.downcase
            iconMap = ActiveSupport::JSON.decode(getFacetExtraInfo(fieldName, 'iconMap'))
            iconMap.each do |icon|
                if(language && icon.language != language) 
                    next
                end
                if(facetValue == icon.value.downcase)
                    return icon.icon
                end
            end
            return defaultValue
        end

        def getThriftFacets

            thriftFacets = Array.new
            @facets.each do |fieldName , facet|
                type = facet['type'];
                order = facet['order'];
                maxCount = facet['maxCount'];
                andSelectedValues =  facet['andSelectedValues']
                if(fieldName == priceFieldName)
                    selectedPriceValues = facetSelectedValue(fieldName, type)
                end

                facetRequest = FacetRequest.new()
                facetRequest.fieldName = fieldName
                facetRequest.numerical = type == 'ranged' ? true : type == 'numerical' ? true : false
                facetRequest.range = type == 'ranged' ? true : false
                facetRequest.boundsOnly = facet['boundsOnly']
                facetRequest.selectedValues = facetSelectedValue(fieldName, type)
                facetRequest.andSelectedValues = andSelectedValues
                facetRequest.sortOrder = order != nil && $order == 1 ? 1 : 2
                facetRequest.maxCount = maxCount != nil && maxCount > 0 ? maxCount : -1
                thriftFacets.push(facetRequest)
            end
            return thriftFacets
        end

        def facetSelectedValue(fieldName, option)
        
            selectedFacets = Array.new
            if (@facets[fieldName]['selectedValues'] != nil) 
                @facets[fieldName]['selectedValues'].each do |value|
                    selectedFacet = FacetValue.new()
                    if (option == 'ranged') 
                        temp = value ;
                        rangedValue = temp.split('-')
                        if (rangedValue[0] != '*') 
                            selectedFacet.rangeFromInclusive = rangedValue[0].to_f
                        end
                        if (rangedValue[1] != '*') 
                            selectedFacet.rangeToExclusive = rangedValue[1].to_f
                            if(rangedValue[0] == rangedValue[1]) 
                                priceRangeMargin = true
                                selectedFacet.rangeToExclusive += 0.01
                            end
                        end
                    else
                        selectedFacet.stringValue = value
                    end
                    selectedFacets.push(selectedFacet)

                end
                return selectedFacets
            end
            return
        end

        def getParentId(fieldName, id)
            hierarchy = Array.new

            searchResult.facetResponses.each do |response|
                if(response.fieldName == fieldName)
                    response.values.each do |item|
                        if(item.hierarchyId == id)
                            hierarchy = item.hierarchy
                            if(hierarchy.length < 4) 
                                return 1
                            end
                        end
                    end
                    response.values.each do |item|
                        if (item.hierarchy.length == hierarchy.length - 1) 
                            if (item.hierarchy[hierarchy.size - 2] == hierarchy[hierarchy.size - 2]) 
                                return item.hierarchyId
                            end
                        end
                    end
                end
            end
        end
    	
    end
end