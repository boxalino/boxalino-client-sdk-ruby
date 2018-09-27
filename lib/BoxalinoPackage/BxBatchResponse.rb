module BoxalinoPackage
  require 'json'
  class BxBatchResponse

    @bxBatchRequests = Array.new
    @response = nil
    @profileItemsFromVariants = nil
    @bxBatchProfileContextsIds = Array.new

    def initialize(response, bxBatchProfileIds = Array.new, bxBatchRequests=Array.new)
      @response = response
      @bxBatchRequests = bxBatchRequests.kind_of?(Array) ? bxBatchRequests : [bxBatchRequests]
      @bxBatchProfileContextsIds = bxBatchProfileIds
    end

    def getBatchResponse
      return @response
    end

    def getHitFieldValuesByProfileId(profileId)
      if(@profileItemsFromVariants.nil?)
        getResultsFromVariants
      end

      if(!@profileItemsFromVariants.nil? && !@profileItemsFromVariants[profileId].nil?)
        return @profileItemsFromVariants[profileId]
      end

      return Array.new
    end

    def getHitFieldValueForProfileIds
      profileItems = Hash.new
      key=0
      @response.variants.each() do |variant|
        items = Array.new
        variant.searchResult.hitsGroups.each() do |hitGroup|
          hitGroup.hits.each() do |hit|
            items.push(hit.values)
          end
        end

        context = @bxBatchProfileContextsIds[key]
        profileItems[context] = items
        key+=1
      end
      @profileItemsFromVariants = profileItems
      return @profileItemsFromVariants
    end

    def getHitValueByField(field)
      profileHits = Hash.new
      key=0
      @response.variants.each() do |variant|
        values = Array.new
        variant.searchResult.hitsGroups.each() do |hitGroup|
          hitGroup.hits.each() do |hit|
            values.push(hit.values[field][0])
          end
        end

        context = @bxBatchProfileContextsIds[key]
        profileHits[context] = values
        key+=1
      end
      return profileHits
    end

    def getHitIds(field='id')
      profileHits = Hash.new
      key=0
      @response.variants.each() do |variant|
        values = Array.new
        variant.searchResult.hitsGroups.each() do |hitGroup|
          hitGroup.hits.each() do |hit|
            values.push(hit.values[field][0])
          end
        end

        context = @bxBatchProfileContextsIds[key]
        profileHits[context] = values
        key+=1
      end
      return profileHits
    end

  end
end