module BoxalinoPackage
  class BxClient
    require 'BoxalinoPackage/p13n_service'
    require 'BoxalinoPackage/thrift'
    require 'BoxalinoPackage/reusing_http_client_transport'
    require 'BoxalinoPackage/persistent_http_client_transport'
    require 'pp'
    require 'securerandom'
    require 'base64'
    require 'BoxalinoPackage/BxChooseResponse'
    require 'BoxalinoPackage/BxAutocompleteResponse'

    @isTest = nil
    @autocompleteRequests = Hash.new
    @autocompleteResponses = Hash.new

    @chooseResponses = nil
    @bundleChooseRequests = Array.new
    @bundleRequests = nil

    @choiceIdOverwrite = "owbx_choice_id"
    VISITOR_COOKIE_TIME = 31536000
    BXL_UUID_REQUEST = "_system_requestid";
    @_timeout = 2
    @_keepAliveTimeout = 30
    @_receiveTimeout = nil
    @_connectionPool = false
    @requestContextParameters = Hash.new

    @sessionId = nil
    @profileId = nil

    @requestMap = Hash.new
    @socketHost = nil
    @socketPort = nil
    @socketSendTimeout = nil
    @socketRecvTimeout = nil
    @notifications = Array.new
    @chooseRequests = Hash.new
    @request = nil
    @CustomCookies = nil
    @apiKey = nil
    @apiSecret = nil


    def initialize(account, password, domain, isDev=false, host=nil, request=nil, params=Hash.new, port=nil, uri=nil, schema=nil, p13n_username=nil, p13n_password=nil, apiKey=nil, apiSecret=nil)
      @account = account
      @password = password
      @isDev = isDev
      @host = host
      @request = request
      if (@host.nil?)
        @host = "cdn.bx-cloud.com"
      end

      @port = port
      if(@port.nil?)
        @port = 443;
      end
      @uri = uri
      if (@uri.nil?)
        @uri = '/p13n.web/p13n'
      end

      @schema = schema
      if(@schema.nil?)
        @schema = 'https'
      end

      @p13n_username = p13n_username
      if(@p13n_username.nil?)
        @p13n_username = "boxalino"
      end

      @p13n_password = p13n_password
      if(@p13n_password.nil?)
        @p13n_password = "tkZ8EXfzeZc6SdXZntCU"
      end
      @domain = domain
      @apiKey = apiKey
      @apiSecret = apiSecret
      @chooseRequests = Array.new
      @requestContextParameters = Hash.new
      @requestMap = Hash.new
      @CustomCookies = nil

      params.each do |key,value|
        addToRequestMap(key, value)
      end

      addRequestContextParameter(BXL_UUID_REQUEST, SecureRandom.uuid)
    end

    def setCookieContainer(cook)
      @CustomCookies = cook
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

    def setSocket(socketHost, socketPort=4040, socketSendTimeout=1000, socketRecvTimeout=1000)
      @socketHost = socketHost
      @socketPort = socketPort
      @socketSendTimeout = socketSendTimeout
      @socketRecvTimeout = socketRecvTimeout
    end

    def setRequestMap(requestMap)
      @requestMap = requestMap
    end

    def getChoiceIdOverwrite
      if (@requestMap.has_key?(:@choiceIdOverwrite) == true)
        return @requestMap[@choiceIdOverwrite]
      end
      return nil
    end

    def getRequestMap
      return @requestMap;
    end
    def addToRequestMap(key, value)
      @requestMap[key] = value
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

    def setSessionAndProfile(sessionId, profileId)
      @sessionId = sessionId
      @profileId = profileId
    end

    def getSessionAndProfile
      if (@sessionId != nil && @profileId != nil)
        return [@sessionId, @profileId]
      end

      if(!@CustomCookies.nil?)
        if (@CustomCookies[:cems].nil?)
          @sessionId = SecureRandom.hex
        else
          @sessionId = @CustomCookies[:cems]
        end
      else
        @sessionId = SecureRandom.hex
      end

      if (!@CustomCookies.nil?)
        if (@CustomCookies[:cemv].nil?)
          @profileId = SecureRandom.hex
        else
          @profileId = @CustomCookies[:cemv]
        end
      else
        @profileId = SecureRandom.hex
      end
      # Refresh cookies
      if (@domain == nil)
        @CustomCookies[:cems] = @sessionId
        @CustomCookies[:cemv] =  { :value => @profileId, :expires => 1.year.from_now }
      else
        @CustomCookies[:cems] =  {:value => @sessionId, :expire =>0 , :path=> '/', :domain => @domain}
        @CustomCookies[:cemv] =  { :value => @profileId, :expires => 1.year.from_now , :path=> '/', :domain => @domain}
      end

      return [@sessionId, @profileId]
    end

    def getUserRecord
      @userRecord = UserRecord.new()
      @userRecord.username = getAccount()
      @userRecord.apiKey = getApiKey()
      @userRecord.apiSecret = getApiSecret()
      return @userRecord
    end

    @transport = nil
    @transport_start = nil
    @updateClient = false
    def getP13n
        @profileId = getSessionAndProfile()[1]

        if(@transport.nil? || @updateClient)
            @transport_start = Time.now
            @updateClient = false
            if(@_connectionPool)
              @transport = Thrift::ReusingHttpClientTransport.new(@schema+"://"+@host+@uri, {})
            else
              @transport = Thrift::PersistentHttpClientTransport.new(@schema+"://"+@host+@uri, {})
            end

            @transport.basic_auth(@p13n_username, @p13n_password)
            @transport.set_profile(@profileId)
        end

        client = P13nService::Client.new(Thrift::CompactProtocol.new(@transport))
        return client
      end

    def getTransportAge
      return Time.now - @transport_start.to_i
    end

    def getChoiceRequest(inquiries, requestContext = nil)
      choiceRequest = ChoiceRequest.new()

      @sessionid = getSessionAndProfile()[0]
      @profileid = getSessionAndProfile()[1]

      choiceRequest.userRecord = getUserRecord()
      choiceRequest.profileId = @profileid
      choiceRequest.inquiries = inquiries
      if (requestContext == nil)
        requestContext = getRequestContext()
      end
      choiceRequest.requestContext = requestContext

      return choiceRequest
    end

    def getIP
      @ip = @request.remote_ip
      return @ip
    end

    def getCurrentURL
      @protocol = @request.protocol
      @hostname = @request.host
      @requesturi = @request.url
      if(@hostname == "")
        return ""
      end
      #return @protocol + '://' + @hostname + @requesturi
      return @requesturi
    end

    def forwardRequestMapAsContextParameters(filterPrefix = '', setPrefix = '')
      @requestMap.each do |key ,value|
        if(filterPrefix != '')
          if(strpos($key, $filterPrefix) != 0)
            continue;
          end
        end
        @requestContextParameters[setPrefix + key] = value.kind_of?(Array)==true ? value : [value]
      end
    end

    def addRequestContextParameter(nname, values)
      if (!values.kind_of?(Array))
        values = Array.new([values])
      end
      @requestContextParameters[nname] = values
    end

    def resetRequestContextParameter
      @requestContextParameters = Hash.new()
    end

    def getBasicRequestContextParameters
      @sessionid = getSessionAndProfile()[0]
      @profileid = getSessionAndProfile()[1]

      return {
          'User-Agent'	 => ['Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.62 Safari/537.36'],
          'User-Host'	  => [getIP()],
          'User-SessionId' => [@sessionid],
          'User-Referer'   => [getCurrentURL()],
          'User-URL'	   => [getCurrentURL()]
      }
    end

    def getRequestContextParameters
      @params = @requestContextParameters
      @chooseRequests.each do |request|
        if(!request.getRequestContextParameters().nil?)
          request.getRequestContextParameters().each do  |k , v|
            if (!v.kind_of?(Array))
              v = Array.new(v)
            end
            @params[k] = v
          end
        end
      end
      return @params
    end

    def getRequestContext
      requestContext = RequestContext.new()
      requestContext.parameters = getBasicRequestContextParameters()
      if(!getRequestContextParameters().nil?)
        getRequestContextParameters().each do |k,v|
          requestContext.parameters[k] = v
        end
      end
      if(!@requestMap.nil?)
        if (@requestMap['p13nRequestContext'].kind_of?(Array))
          tempArray = @requestMap['p13nRequestContext']
          requestContext.parameters = tempArray.merge(requestContext.parameters)

        end
      end
      return requestContext
    end

    def  throwCorrectP13nException(e, extra = {})
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

      jsonEncode = ActiveSupport::JSON
      exceptionMessage = e.to_s
      backtrace = e.backtrace
      exceptionFull = ["Message", exceptionMessage, "Backtrace", backtrace, "Choice Request", jsonEncode.encode(@choiceRequest), "Autocomplete Request", jsonEncode.encode(@p13nrequests), "Extra case", jsonEncode.encode(extra)]
      raise exceptionFull.join("\n")
    end

    def p13nchoose(choiceRequest, responseFallback = true)
      begin
        clientTry = 1
        begin
          client = getP13n
        rescue Exception => e
          clientTry = 2
          @updateClient = true
          client = getP13n
        end

        choiceResponse = client.choose(choiceRequest)
        if(!@requestMap.nil?)
          if(!@requestMap['dev_bx_debug'].nil?)
            addNotification('bxRequest', choiceRequest)
            addNotification('bxResponse', choiceResponse)
          end

          if(!@requestMap['dev_bx_disp'].nil?)
            jsonEncode = ActiveSupport::JSON
            _tempOutPut = Array.new(['<pre><h1>Choice Request</h1>'])
            _tempOutPut.push(jsonEncode.encode(choiceRequest))
            _tempOutPut.push("<br><h1>Choice Response</h1>")
            _tempOutPut.push(jsonEncode.encode(choiceResponse))
            _tempOutPut.push("</pre>")
            raise(_tempOutPut.join(' '))
          end
        end
        return choiceResponse
      rescue Timeout::Error => te
        if(responseFallback)
          @updateClient = true
          p13nchoose(choiceRequest, false)
        else
          throwCorrectP13nException(te, {"attempt"=>2, "client try"=>clientTry, "timeout-exception"=>true, "transport_age"=> getTransportAge})
        end
      rescue Exception => e
        if(responseFallback)
          @updateClient = true
          p13nchoose(choiceRequest, false)
        else
          throwCorrectP13nException(e, {"attempt"=>2, "client try"=>clientTry, "timeout-exception"=>false, "transport_age"=> getTransportAge})
        end
      end
    end

    def p13nchooseAll(choiceRequestBundle, responseFallback = true)
      begin
        clientTry = 1
        begin
          client = getP13n
        rescue Exception => e
          clientTry = 2
          @updateClient = true
          client = getP13n
        end

        bundleChoiceResponse = client.chooseAll(choiceRequestBundle)
        if(!@requestMap['dev_bx_disp'].nil?)
          jsonEncode = ActiveSupport::JSON
          _tempOutPut = Array.new(['<pre><h1>Bundle Choice Request</h1>'])
          _tempOutPut.push(jsonEncode.encode(requestBundle))
          _tempOutPut.push("<br><h1>Bundle Choice Response</h1>")
          _tempOutPut.push(jsonEncode.encode(bundleChoiceResponse))
          _tempOutPut.push("</pre>")
          raise(_tempOutPut.join(' '))
        end
        return bundleChoiceResponse
      rescue Exception => e
        if(responseFallback)
          @updateClient = true
          p13nchooseAll(choiceRequestBundle, false)
        else
          throwCorrectP13nException(e, {"attempt"=>2, "client try"=>clientTry})
        end
      end
    end

    def addRequest(request)
      request.setDefaultIndexId(getAccount())
      request.setDefaultRequestMap(@requestMap)
      @chooseRequests.push(request)
      return @chooseRequests.size
    end

    def addBundleRequest(requests)
      requests.each do |request|
        request.setDefaultIndexId(getAccount())
        request.setDefaultRequestMap(@requestMap)
      end
      @bundleChooseRequests.push(requests)
    end

    def resetRequests
      @chooseRequests = Array.new
      @bundleChooseRequests = Array.new
    end

    def getRequest(iindex=0)
      if(@chooseRequests.length <= iindex)
        return nil
      end
      return @chooseRequests[iindex]
    end

    def getChoiceIdRecommendationRequest(choiceId)
      @chooseRequests.each do |request|
        if (request.getChoiceId() == choiceId)
          return request
        end
      end
      return nil
    end

    def getRecommendationRequests
      requests = Array.new()
      @chooseRequests.each do  |request|
        if(request.instance_of?(BxRecommendationRequest))
          requests[] = request
        end
      end
      return requests
    end

    def getThriftChoiceRequest(ssize=0)
      if(@chooseRequests.size == 0 && @autocompleteRequests.size > 0)
        @sessionid = getSessionAndProfile()[0]
        @profileid = getSessionAndProfile()[1]
        @userRecord = getUserRecord()
        tempArray = @autocompleteRequests
        @p13nrequests = tempArray.map { |request| request.getAutocompleteThriftRequest(@profileid, @userRecord) }
        return @p13nrequests
      end

      @choiceInquiries = Array.new()

      @chooseRequests.each do |request|
        @choiceInquiry = ChoiceInquiry.new()
        @choiceInquiry.choiceId = request.getChoiceId()
        if(@isTest == true || (@isDev == true && @isTest == nil))
          @choiceInquiry.choiceId = @choiceInquiry.choiceId + "_debugtest"
        end
        @choiceInquiry.simpleSearchQuery = request.getSimpleSearchQuery()
        @choiceInquiry.contextItems = request.getContextItems()
        @choiceInquiry.minHitCount = request.getMin().to_i
        @choiceInquiry.withRelaxation = request.getWithRelaxation()

        @choiceInquiries.push(@choiceInquiry)
      end

      @choiceRequest = getChoiceRequest(@choiceInquiries, getRequestContext())
      return @choiceRequest
    end

    def getBundleChoiceRequest(inquiries, requestContext = nil)
      choiceRequest = ChoiceRequest()
      @sessionid = getSessionAndProfile()[0]
      @profileid = getSessionAndProfile()[1]

      choiceRequest.userRecord = getUserRecord()
      choiceRequest.profileId = @profileid
      choiceRequest.inquiries = @inquiries
      if(requestContext == nil)
        requestContext = getRequestContext()
      end
      choiceRequest.requestContext = requestContext
      return choiceRequest
    end

    def getThriftBundleChoiceRequest
      bundleRequest = Array.new()
      @bundleChooseRequests.each do |bundleChooseRequest|
        choiceInquiries = Array.new()
        bundleChooseRequest.each do |request|
          addRequest(request)
          choiceInquiry = ChoiceInquiry()
          choiceInquiry.choiceId = request.getChoiceId()
          if(@isTest == true || (@isDev == true && @isTest == nil))
            choiceInquiry.choiceId = choiceInquiry.choiceId + "_debugtest"
          end
          choiceInquiry.simpleSearchQuery = request.getSimpleSearchQuery(getAccount())
          choiceInquiry.contextItems = request.getContextItems()
          choiceInquiry.minHitCount = request.getMin()
          choiceInquiry.withRelaxation = request.getWithRelaxation()
          choiceInquiries.push(choiceInquiry)
        end
        bundleRequest.push(getBundleChoiceRequest(choiceInquiries, getRequestContext()))
      end

      @bundleRequests = ChoiceRequestBundle.new(['requests' => bundleRequest])
      return @bundleRequests
    end

    def choose(chooseAll=false, ssize=0)
      if(chooseAll == true)
        bundleResponse = p13nchooseAll(getThriftBundleChoiceRequest())
        variants = Array.new
        bundleResponse.responses.each do  |choiceResponse|
          variants = variants.merge(choiceResponse.variants)
        end

        response = ChoiceResponse.new(['variants' => variants])
      else
        response = p13nchoose(getThriftChoiceRequest(ssize))
        if(ssize > 0)
          response.variants = response.variants.merge(@chooseResponses.variants)
        end
      end
      @chooseResponses = response
    end

    def flushResponses
      @autocompleteResponses = nil
      @chooseResponses = nil
    end

    def getResponse(chooseAll=false)
      _chResponseSize = 0
      if not @chooseResponses.nil?
        _chResponseSize = @chooseResponses.variants.size
      end
      if( (@chooseResponses == nil || !@chooseResponses.any?) == true)
        choose(chooseAll)
      elsif (@size = @chooseRequests.size - _chResponseSize)
        choose(chooseAll, @size);
      end
      if (@chooseResponses.variants.nil?)
        raise "no variants in response for request: " + ActiveSupport::JSON.encode(@choiceRequest)
      end

      bxChooseResponse = BxChooseResponse.new(@chooseResponses, @chooseRequests)
      bxChooseResponse.setNotificationMode(getNotificationMode())
      return bxChooseResponse
    end

    def getNotificationMode
      if(!@requestMap.nil?)
        if(!@requestMap['dev_bx_notifications'].nil?)
          return true
        else
          return false
        end
      end
      return false
    end

    def setAutocompleteRequest(request)
      setAutocompleteRequests([request])
    end

    def setAutocompleteRequests(requests)
      requests.each do |request|
        enhanceAutoCompleterequest(request)
      end
      @autocompleteRequests = requests
    end

    def enhanceAutoCompleterequest(request)
      request.setDefaultIndexId(getAccount())
    end

    def p13nautocomplete(autocompleteRequest, responseFallback = true)
      begin
        clientTry = 1
        begin
          client = getP13n
        rescue Exception => e
          clientTry = 2
          @updateClient = true
          client = getP13n
        end

        choiceResponse = client.choose(autocompleteRequest)
        if(!@requestMap['dev_bx_disp'].nil? )
          jsonEncode = ActiveSupport::JSON
          _tempOutPut = Array.new(['<pre><h1>Autocomplete Request</h1>'])
          _tempOutPut.push(jsonEncode.encode(autocompleteRequest))
          _tempOutPut.push("<br><h1>Choice Response</h1>")
          _tempOutPut.push(jsonEncode.encode(choiceResponse))
          _tempOutPut.push("</pre>")
          raise(_tempOutPut.join(' '))
        end
        return choiceResponse
      rescue Exception => e
        if(responseFallback)
          @updateClient = true
          p13nautocomplete(autocompleteRequest, false)
        else
          throwCorrectP13nException(e, {"attempt"=>2, "client try"=>clientTry})
        end
      end
    end

    def autocomplete
      @sessionid = getSessionAndProfile()[0]
      @profileid = getSessionAndProfile()[1]
      @userRecord = getUserRecord()

      tempArray = @autocompleteRequests
      @p13nrequests = tempArray.map { |request| request.getAutocompleteThriftRequest(@profileid, @userRecord) }
      @i = -1

      tempArrayBxAuto = p13nautocompleteAll(@p13nrequests)
      if(tempArrayBxAuto.nil?)
         tempArrayBxAuto = Hash.new
      end
      @autocompleteResponses = tempArrayBxAuto.map { |request| autocompletePartail(request , ++@i) }
    end

    def autocompletePartail(response, i)
      request = @autocompleteRequests[i]
      return  BxAutocompleteResponse.new(response, request)
    end

    def getAutocompleteResponse
      responses = getAutocompleteResponses()
      if(!responses.nil?)
        return responses[0]
      end
      return nil
    end

    def p13nautocompleteAll(requests, responseFallback = true)
      requestBundle = AutocompleteRequestBundle.new()
      requestBundle.requests = requests
      begin
        clientTry = 1
        begin
          client = getP13n
        rescue Exception => e
          clientTry = 2
          @updateClient = true
          client = getP13n
        end

        choiceResponse = client.autocompleteAll(requestBundle).responses
        if(!@requestMap.nil?)
          if(!@requestMap['dev_bx_disp'].nil?)
            jsonEncode = ActiveSupport::JSON
            _tempOutPut = Array.new(['<pre><h1>Autocomplete ALL Request bundle</h1>'])
            _tempOutPut.push(jsonEncode.encode(requestBundle))
            _tempOutPut.push("<br><h1>Choice Response</h1>")
            _tempOutPut.push(jsonEncode.encode(choiceResponse))
            _tempOutPut.push("</pre>")
            raise(_tempOutPut.join(' '))
          end
        end
        return choiceResponse
      rescue Exception => e
        if(responseFallback)
          @updateClient = true
          p13nautocompleteAll(requests, false)
        else
          throwCorrectP13nException(e, {"attempt"=>2, "client try"=>clientTry})
        end
      end
    end

    def getAutocompleteResponses
      if (@autocompleteResponses.nil?)
        autocomplete()
      end
      return @autocompleteResponses
    end

    def setTimeout(timeout)
      @_timeout = timeout
    end

    def notifyWarning(warning)
      addNotification("warning", warning)
    end

    def addNotification(type, notification)
      if(@notifications.nil?)
        @notifications = Hash.new
      end
      if(@notifications && @notifications[type].nil?)
        @notifications[type] = Array.new()
      end
      @notifications[type].push(notification)
    end

    def finalNotificationCheck(force=false, requestMapKey = 'dev_bx_notifications')
      if (force == true || (!@requestMap[requestMapKey].nil?))
        puts "<pre><h1>Notifications</h1>"
        pp(@notifications)
        puts "</pre>"
        exit
      end
    end

    def getNotifications
      final = @notifications
      final['response'] = getResponse().getNotifications()
      return final
    end

    def getSystemRequestId
       if (@requestContextParameters.key?(BXL_UUID_REQUEST))
          return @requestContextParameters[BXL_UUID_REQUEST][0]
       end

       return nil
    end

    def set_connection_timeout(timeout)
       @_timeout = timeout
    end

    def set_receive_timeout(timeout)
      @_receiveTimeout = timeout
    end

    def set_keep_alive_timeout(timeout)
      @_keepAliveTimeout = timeout
    end

    def set_use_connection_pool(value)
    @_connectionPool = value
    end

  end
end