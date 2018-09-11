require 'thrift'
require 'pp'
require 'p13n_service'
require 'securerandom'
require 'base64'
require 'BxChooseResponse'
require 'BxAutocompleteResponse'
class BxClient

	attr_reader :controller

	@isTest = nil
	@autocompleteRequests = nil
	@autocompleteResponses = nil


	@chooseResponses = nil
	@bundleChooseRequests = Array.new
	VISITOR_COOKIE_TIME = 31536000
	@_timeout = 2
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
	def initialize( account, password, domain, isDev=false, host=nil, request=nil, port=nil, uri=nil, schema=nil, p13n_username=nil, p13n_password=nil)
		@account = account
		@password = password
		#To Check Below Line
		#	@requestMap = params
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
		@chooseRequests = Array.new
		@requestContextParameters = Hash.new
		@requestMap = Hash.new
		@CustomCookies = nil
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


	def setSocket(socketHost, socketPort=4040, socketSendTimeout=1000, socketRecvTimeout=1000)
		@socketHost = socketHost
		@socketPort = socketPort
		@socketSendTimeout = socketSendTimeout
		@socketRecvTimeout = socketRecvTimeout
	end

	def setRequestMap(requestMap)
		@requestMap = requestMap
	end


	choiceIdOverwrite = "owbx_choice_id"

	def getChoiceIdOverwrite
		if (@requestMap.has_key?(:@choiceIdOverwrite) == true)
			return requestMap[@choiceIdOverwrite]
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
		return @userRecord
	end

	@@transport = nil
	def getP13n(timeout=2, useCurlIfAvailable=true)
		@profileId = getSessionAndProfile()[1]

		if(@@transport == nil)
			@@transport = Thrift::ReusingHTTPClientTransport.new(@schema+"://"+@host+@uri)
			@@transport.basic_auth(@p13n_username, @p13n_password)
			@@transport.set_profile(@profileId)
		end

		client = P13nService::Client.new(Thrift::CompactProtocol.new(@@transport))
		return client
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

	def   getIP
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

	def  throwCorrectP13nException(e)

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

	def p13nchoose(choiceRequest)
		begin
			# getP13n(@_timeout)
			choiceResponse = getP13n(@_timeout).choose(choiceRequest)
			if(!@requestMap.nil?)
				if(!@requestMap['dev_bx_debug'].nil? && @requestMap['dev_bx_debug'] == 'true')
					addNotification('bxRequest', choiceRequest)
					addNotification('bxResponse', choiceResponse)
				end

				if(!@requestMap['dev_bx_disp'].nil? && @requestMap['dev_bx_disp'] == 'true')
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
		rescue Exception => e
			throwCorrectP13nException(e)
		end
	end

	def p13nchooseAll(choiceRequestBundle)
		begin
			bundleChoiceResponse = getP13n(@_timeout).chooseAll(choiceRequestBundle)
			if(@requestMap['dev_bx_disp'].kind_of?(Array) )
				puts "<pre><h1>Bundle Choice Request</h1>"
				pp(choiceRequestBundle)
				puts "<br><h1>Bundle Choice Response</h1>"
				pp(bundleChoiceResponse)
				puts "</pre>"
				exit;
			end
			return bundleChoiceResponse
		rescue Exception => e
			throwCorrectP13nException(e)
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
			# getAccount()
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
		return ChoiceRequestBundle.new(['requests' => bundleRequest])
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
				response.variants = response.variants.merge(chooseResponses.variants)
			end
		end
		@chooseResponses = p13nchoose(getThriftChoiceRequest())
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
		bxChooseResponse = BxChooseResponse.new(@chooseResponses, @chooseRequests)
		bxChooseResponse.setNotificationMode(getNotificationMode())
		return bxChooseResponse
	end

	def getNotificationMode
		if(!@requestMap.nil?)
			if(!@requestMap['dev_bx_notifications'].nil? && @requestMap['dev_bx_notifications'] == true)
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

	def p13nautocomplete(autocompleteRequest)
		begin
			choiceResponse = getP13n(@_timeout).choose(choiceRequest)
			if(@requestMap['dev_bx_disp'].kind_of?(Array) )
				puts "<pre><h1>Autocomplete Request</h1>"
				pp(autocompleteRequest)
				puts "<br><h1>Choice Response</h1>"
				pp(choiceResponse)
				puts "</pre>"
				exit;
			end
			return choiceResponse
		rescue Exception => e
			throwCorrectP13nException(e)
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


	def  p13nautocompleteAll(requests)
		requestBundle = AutocompleteRequestBundle.new()
		requestBundle.requests = requests
		begin
			choiceResponse = getP13n(@_timeout).autocompleteAll(requestBundle).responses
			if(!@requestMap.nil?)
				if(@requestMap['dev_bx_disp'].kind_of?(Array) )
					puts "<pre><h1>Request bundle</h1>"
					pp(requestBundle)
					puts "<br><h1>Choice Response</h1>"
					pp(choiceResponse)
					puts "</pre>"
					exit;
				end
			end
			return choiceResponse
		rescue Exception => e
			throwCorrectP13nException(e)
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
		if(!notifications[type].nil?)
			notifications[type] = Array.new()
		end
		notifications[type].push(notification)
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

	def finalNotificationCheck(force=false, requestMapKey = 'dev_bx_notifications')

		if (force == true || (!@requestMap[requestMapKey].nil? ))
			puts "<pre><h1>Notifications</h1>"
			pp(@notifications)
			puts "</pre>"
			exit
		end
	end
end