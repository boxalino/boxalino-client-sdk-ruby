module BoxalinoPackage
  class BxBatchClient
    require 'BoxalinoPackage/p13n_service'
    require 'BoxalinoPackage/thrift'
    require 'BoxalinoPackage/reusing_http_client_transport'
    require 'pp'
    require 'securerandom'
    require 'base64'
    require 'BoxalinoPackage/BxBatchRequest'
    require 'BoxalinoPackage/BxBatchResponse'

    @isTest = nil
    @batchChooseResponse = nil

    @apiKey = nil
    @apiSecret = nil
    @@transport = nil
    @schema = 'https'
    @batchRequest = nil
    @batchChooseRequest = nil

    def initialize(account, password, domain, isDev=false, apiKey=nil, apiSecret=nil)
      @account = account
      @password = password
      @domain = domain
      @isDev = isDev
      @apiKey = apiKey
      @apiSecret = apiSecret

      @host = "track.bx-cloud.com/track"
      @uri = '/p13n.web/p13n'
      @schema = 'https'
      @batchSize =1000

      @notifications = Hash.new
      @requestContextParameters = Hash.new
      @batchChooseRequests = Array.new
    end

    def setRequest(request)
      request.setDefaultIndexId(getAccount(@isDev))
      request.setRequestContextParameters(@requestContextParameters)
      request.setIsDev(@isDev)

      @batchRequest = request
    end

    def getBatchChooseResponse
      _batchChooseResponseSize = 0
      if not @batchChooseResponse.nil?
        _batchChooseResponseSize = @batchChooseResponse.variants.size
      end
      if( (@batchChooseResponse == nil || !@batchChooseResponse.any?) == true)
        @batchChooseResponse = batchChoose
      end
      bxBatchChooseResponse = BxBatchResponse.new(@batchChooseResponse, @batchRequest.getProfileIds)
      return bxBatchChooseResponse
    end

    def batchChoose
      requests = getThriftBatchChoiceRequest
      if(requests.kind_of?(Array))
        variants = Array.new
        selectedVariants = Array.new
        #it means that the batch size has been exceeded
        requests.each do |request|
          response = p13nBatch(request)
          response.variants.each do |variant|
            variants.push(variant)
          end
          response.selectedVariants.each do |selectedVariant|
            selectedVariants.push(selectedVariant)
          end
        end
        @batchChooseResponse = BatchChoiceResponse.new('variants' => variants, 'selectedVariants'=>selectedVariants)
        return @batchChooseResponse
      end

      @batchChooseResponse = p13nBatch(requests)
      return @batchChooseResponse
    end

    def getThriftBatchChoiceRequest
      requestProfiles = @batchRequest.getProfileIds
      if(requestProfiles.length > @batchSize)
        requestProfiles.each_slice(@batchSize) do |groupProfileIds|
          request = getBatchChooseRequest(@batchRequest, groupProfileIds)
          addBatchChooseRequest(request)
        end

        return @batchChooseRequests
      end

      @batchChooseRequest = getBatchChooseRequest(@batchRequest)
      return @batchChooseRequest
    end

    def addBatchChooseRequest(request)
      if(@batchChooseRequests.nil? || @batchChooseRequests.empty?)
        @batchChooseRequests = Array.new
      end

      @batchChooseRequests.push(request)
    end

    def getBatchChooseRequest(request, profileIds = Array.new)
      batchRequest = BatchChoiceRequest.new()
      batchRequest.userRecord = getUserRecord
      batchRequest.profileIds = [getAccount]
      batchRequest.choiceInquiry = ChoiceInquiry.new
      batchRequest.requestContext = RequestContext.new
      batchRequest.profileContexts = request.getProfileContextList(profileIds)
      batchRequest.choiceInquiries = request.getChoiceInquiryList

      return batchRequest
    end

    def p13nBatch(batchChoiceRequest)
      begin
        batchChooseResponse = getP13n.batchChoose(batchChoiceRequest)
        if(!@requestContextParameters.nil?)
          if(!@requestContextParameters['dev_bx_debug'].nil? && @requestContextParameters['dev_bx_debug'] == 'true')
            addNotification('bxBatchRequest', batchChoiceRequest)
            addNotification('bxBatchResponse', batchChooseResponse)
          end

          if(!@requestContextParameters['dev_bx_disp'].nil? && @requestContextParameters['dev_bx_disp'] == 'true')
            jsonEncode = ActiveSupport::JSON
            _tempOutPut = Array.new(["pre><h1>Batch Request</h1>"])
            _tempOutPut.push(jsonEncode.encode(batchChoiceRequest))
            _tempOutPut.push("<br><h1>Batch Response</h1>")
            _tempOutPut.push(jsonEncode.encode(batchChooseResponse))
            _tempOutPut.push("</pre>")
            raise(_tempOutPut.join(' '))
          end
        end
        return batchChooseResponse
      rescue Exception => e
        throwCorrectP13nException(e)
      end
    end

    def getP13n
      if(@@transport == nil)
        if(@apiKey.nil? || @apiSecret.nil?)
          @host = "api.bx-cloud.com"
          @apiKey = "boxalino"
          @apiSecret = "tkZ8EXfzeZc6SdXZntCU"
        end

        @@transport = Thrift::ReusingHTTPClientTransport.new(@schema+"://"+@host+@uri)
        @@transport.basic_auth(getApiKey(), getApiSecret())
      end
      client = P13nService::Client.new(Thrift::CompactProtocol.new(@@transport))
      return client
    end

    def getUserRecord
      @userRecord = UserRecord.new()
      @userRecord.username = getAccount(@isDev)
      @userRecord.apiKey = getApiKey()
      @userRecord.apiSecret = getApiSecret()
      return @userRecord
    end

    def resetBatchRequests
      @batchChooseRequests = Array.new
    end

    def flushResponses
      @batchChooseResponse = nil
    end

    #duplicate from BxClient.rb
    def throwCorrectP13nException(e)
      if(e.to_s.index( 'Could not connect ') != nil)
        raise 'The connection to our server failed even before checking your credentials. This might be typically caused by 2 possible things: wrong values in host, port, schema or uri (typical value should be host=cdn.bx-cloud.com, port=443, uri =/p13n.web/p13n and schema=https, your values are : host=' + @host + ', port=' + @port + ', schema=' + @schema + ', uri=' + @uri + '). Another possibility, is that your server environment has a problem with ssl certificate (peer certificate cannot be authenticated with given ca certificates), which you can either fix, or avoid the problem by adding the line "curl_setopt(self::$curlHandle, CURLOPT_SSL_VERIFYPEER, false);" in the file "lib\Thrift\Transport\P13nTCurlClient" after the call to curl_init in the function flush. Full error message=' + e.to_s
      end
      if( e.to_s.index(  'Bad protocol id in TCompact message') !=nil)
        raise 'The connection to our server has worked, but your credentials were refused. Provided credentials username=' + @p13n_username + ', password=' + @p13n_password + '. Full error message=' + e.to_s
      end
      if(e.to_s.index('choice not found') != nil)
        msg = e.to_s
        parts = msg.split('choice not found')
        pieceMsg  = parts[0]
        pieces = pieceMsg.split(' at ')
        choiceId = pieces[0]
        choiceId[':'] = ""
        raise "Configuration not live on account " + getAccount() + ": choice $choiceId doesn't exist. NB: If you get a message indicating that the choice doesn't exist, go to http://intelligence.bx-cloud.com, log in your account and make sure that the choice id you want to use is published."
      end

      if(e.to_s.index('Solr returned status 404') !=nil)
        raise "Data not live on account " + getAccount() + ": index returns status 404. Please publish your data first, like in example backend_data_basic.php."
      end

      if( e.to_s.index('undefined field') != nil)
        msg = e.to_s
        parts = msg.split('undefined field')
        piecesMsg = parts[1]
        pieces = piecesMsg.split(' at ')
        field = pieces[0]
        field[":"] = ""
        raise "You request in your filter or facets a non-existing field of your account " + getAccount() + ": field $field doesn't exist."
      end
      if(e.to_s.index('All choice variants are excluded') != nil)
        raise "You have an invalid configuration for with a choice defined, but having no defined strategies. This is a quite unusual case, please contact support@boxalino.com to get support."
      end
      raise e.to_s
    end

    def addRequestContextParameter(name, values)
      if (!values.kind_of?(Array))
        values = Array.new([values])
      end
      @requestContextParameters[name] = values
    end

    def resetRequestContextParameter
      @requestContextParameters = Hash.new()
    end

    def setTimeout(timeout)
      @_timeout = timeout
    end

    def setHost(host)
      @host = host
    end

    def setTestMode(isTest)
      @isTest = isTest
    end

    def setApiKey(apiKey)
      @apiKey = apiKey
    end

    def setApiSecret(apiSecret)
      @apiSecret = apiSecret
    end

    def getAccount(checkDev = true)
      if(checkDev == true && @isDev == true)
        return @account + '_dev'
      end
      return @account
    end

    def getUsername
      return getAccount(false)
    end

    def getPassword
      return @password
    end

    def getApiKey
      return @apiKey
    end

    def getApiSecret
      return @apiSecret
    end

  end
end