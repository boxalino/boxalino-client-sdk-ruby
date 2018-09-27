module BoxalinoPackage
  require 'BoxalinoPackage/BxRequest'
  class BxBatchRequest < BxRequest
    @language = nil
    @choiceId
    @max = 10
    @min = 0
    @profileIds = Array.new
    @choiceInquiryList = Array.new
    @isTest = false
    @isDev = false
    @requestContextParameters = Hash.new
    @profileContextList = Array.new
    @sameInquiry = true

    def initialize(language, choiceId, max=10, min=0)
      if(choiceId.nil?)
        raise  'BxBatchRequest created with null choiceId'
      end
      @language = language
      @choiceId = choiceId
      @max = max
      @min = min

      @sameInquiry = true
      @requestContextParameters = Hash.new
      @profileContextList = Array.new
      @profileIds = Array.new
      @choiceInquiryList = Array.new

      #configurations from parent initialize
      @bxFacets = BxFacets.new

      @bxSortFields = BxSortFields.new #Array.new
      @bxFilters = Hash.new
      @orFilters = false
      @hitsGroupsAsHits = nil
      @withRelaxation = choiceId == 'search'
      @contextItems = Array.new
      @@returnFields= Array.new
    end

    def getChoiceInquiryList
      if(@profileIds.nil?)
        return Array.new
      end

      @choiceInquiryList = Array.new
      if(@sameInquiry)
        choiceInquiry = createMainInquiry
        @choiceInquiryList.push(choiceInquiry)
      end

      return @choiceInquiryList
    end

    def getProfileContextList(setOfProfileIds = Array.new)
      if(@profileIds.nil? && setOfProfileIds.empty?)
        return Array.new
      end

      profileIds = setOfProfileIds
      if(setOfProfileIds.empty?)
        profileIds = getProfileIds
      end
      @profileContextList = Array.new
      profileIds.each do |id|
        addProfileContext(id)
      end

      return @profileContextList
    end

    def getSimpleSearchQuery
      searchQuery  = SimpleSearchQuery.new
      searchQuery.indexId = getIndexId()
      searchQuery.language = @language
      searchQuery.returnFields = getReturnFields()
      searchQuery.hitCount = @max
      searchQuery.queryText = getQuerytext()
      searchQuery.groupBy = getGroupBy()
      _temp =getFilters()
      if(!_temp.nil?)
        if (_temp.length >0)
          searchQuery.filters = Array.new
          getFilters().each do |filter|
            searchQuery.filters.push(filter[1].getThriftFilter())
          end
        end
      end
      searchQuery.orFilters = getOrFilters()
      if(getSortFields())
        searchQuery.sortFields = getSortFields().getThriftSortFields()
      end
      return searchQuery
    end

    def getRequestContext(id)
      requestContext = RequestContext.new()
      requestContext.parameters = Hash.new
      if(!@requestContextParameters.nil?)
        @requestContextParameters.each do |k,v|
          requestContext.parameters[k] = v
        end
      end
      requestContext.parameters['customerId'] = [id.to_s]
      return requestContext
    end

    def createMainInquiry
      choiceInquiry = ChoiceInquiry.new()
      choiceInquiry.choiceId = @choiceId
      if(@isTest == true || (@isDev == true && @isTest == nil))
        choiceInquiry.choiceId = @choiceId + "_debugtest"
      end
      choiceInquiry.simpleSearchQuery = getSimpleSearchQuery
      choiceInquiry.contextItems = getContextItems
      choiceInquiry.minHitCount = @min
      choiceInquiry.withRelaxation = getWithRelaxation

      return choiceInquiry
    end

    def addProfileContext(id, requestContext=nil)
      if(requestContext.nil?)
        requestContext = getRequestContext(id)
      end
      profileContext = ProfileContext.new
      profileContext.profileId = id.to_s
      profileContext.requestContext = requestContext
      @profileContextList.push(profileContext)

      return @profileContextList
    end

    def addChoiceInquiry(newChoiceInquiry)
      @choiceInquiryList.push(newChoiceInquiry)
      return @choiceInquiryList
    end

    def setUseSameChoiceInquiry(sameInquiry)
      @sameInquiry = true
    end

    def setProfileIds(ids)
      @profileIds = ids
    end

    def getProfileIds
      return @profileIds
    end

    def getContextItems
      return @contextItems
    end

    def setRequestContextParameters(requestParams)
      @requestContextParameters = requestParams
    end

    def setIsDev(dev)
      @isDev = dev
    end


  end
end
