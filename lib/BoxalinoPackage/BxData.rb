module BoxalinoPackage
    require 'csv'
    require "yaml"
    require 'builder'
    require 'rubygems'
    require 'zip'
    require 'tmpdir'
    require 'FileUtils'
    require 'open-uri'

    class BxData
    	
    	URL_VERIFY_CREDENTIALS = '/frontend/dbmind/en/dbmind/api/credentials/verify'
        URL_XML = '/frontend/dbmind/en/dbmind/api/data/source/update'
        URL_PUBLISH_CONFIGURATION_CHANGES = '/frontend/dbmind/en/dbmind/api/configuration/publish/owner'
        URL_ZIP = '/frontend/dbmind/en/dbmind/api/data/push'
    	URL_EXECUTE_TASK = '/frontend/dbmind/en/dbmind/files/task/execute'

        @bxClient = ""
        @languages = ""
        @isDev = ""
        @isDelta =""

        @sources = Hash.new()
        @sourceIdContainers = Hash.new()



        def initialize(bxClient, languages = Array.new, isDev=false, isDelta=false) 
            @bxClient = bxClient
            @languages = languages
            @isDev = isDev
            @isDelta = isDelta
            @host = 'http://di1.bx-cloud.com'
            @ftpSources = Hash.new()
            @owner = 'bx_client_data_api'
        end

        def setLanguages(languages) 
            @languages = languages
        end

        def getLanguages
            return @languages
        end

        def addMainXmlItemFile(filePath, itemIdColumn, xPath='', encoding = 'UTF-8', sourceId = 'item_vals', container = 'products', validate=true) 
            sourceKey = addXMLItemFile(filePath, itemIdColumn, xPath, encoding, sourceId, container, validate)
            addSourceIdField(sourceKey, itemIdColumn, 'XML', nil, validate) 
            addSourceStringField(sourceKey, "bx_item_id", itemIdColumn, nil, validate) 
            return sourceKey
        end

        def addMainCSVItemFile(filePath, itemIdColumn, encoding = 'UTF-8', delimiter = ',', enclosure = "\"", escape = "\\\\", lineSeparator = "\\n", sourceId = 'item_vals', container = 'products', validate=true) 
            sourceKey = addCSVItemFile(filePath, itemIdColumn, encoding, delimiter, enclosure, escape, lineSeparator, sourceId, container, validate)
            addSourceIdField(sourceKey, itemIdColumn, 'CSV', nil, validate) 
            addSourceStringField(sourceKey, "bx_item_id", itemIdColumn, nil, validate) 
            return sourceKey
        end

        def addMainCSVCustomerFile(filePath, itemIdColumn, encoding = 'UTF-8', delimiter = ',', enclosure = "\&", escape = "\\\\", lineSeparator = "\\n", sourceId = 'customers', container = 'customers', validate=true) 
            sourceKey = addCSVItemFile(filePath, itemIdColumn, encoding, delimiter, enclosure, escape, lineSeparator, sourceId, container, validate)
            addSourceIdField(sourceKey, itemIdColumn, 'CSV', nil, validate) 
            addSourceStringField(sourceKey, "bx_customer_id", itemIdColumn, nil, validate) 
            return sourceKey
        end

        def addCSVItemFile(filePath,itemIdColumn, encoding = 'UTF-8', delimiter = ',', enclosure = "&", escape = "\\\\", lineSeparator = "\\n", sourceId = nil, container = 'products', validate=true, maxLength=23)
            params = {'itemIdColumn'=>itemIdColumn, 'encoding'=>encoding, 'delimiter'=>delimiter, 'enclosure'=>enclosure, 'escape'=>escape, 'lineSeparator'=>lineSeparator}
            if(sourceId == nil) 
                sourceId = getSourceIdFromFileNameFromPath(filePath, container, maxLength, true)
            end
            return addSourceFile(filePath, sourceId, container, 'item_data_file', 'CSV', params, validate)
        end

        def addXMLItemFile(filePath, itemIdColumn, xPath, encoding = 'UTF-8', sourceId = nil, container = 'products', validate=true, maxLength=23)
            params = {'itemIdColumn'=>itemIdColumn, 'encoding'=>encoding, 'baseXPath'=>xPath}
            if(sourceId == nil) 
                sourceId = getSourceIdFromFileNameFromPath(filePath, container, maxLength, true)
            end
            return addSourceFile(filePath, sourceId, container, 'item_data_file', 'XML', params, validate)
        end

        def addCSVCustomerFile(filePath, itemIdColumn, encoding = 'UTF-8', delimiter = ',', enclosure = "\&", escape = "\\\\", lineSeparator = "\\n", sourceId = nil, container = 'customers', validate=true, maxLength=23) 
            params = array('itemIdColumn'=>itemIdColumn, 'encoding'=>encoding, 'delimiter'=>delimiter, 'enclosure'=>enclosure, 'escape'=>escape, 'lineSeparator'=>lineSeparator);
            if(sourceId == nil) 
                sourceId = getSourceIdFromFileNameFromPath(filePath, container, maxLength, true);
            end
            return addSourceFile(filePath, sourceId, container, 'item_data_file', 'CSV', params, validate);
        end

        def addCategoryFile(filePath, categoryIdColumn, parentIdColumn, categoryLabelColumns, encoding = 'UTF-8', delimiter = ',', enclosure = "\&", escape = "\\\\", lineSeparator = "\\n", sourceId = 'resource_categories', container = 'products', validate=true) 
            params = {'referenceIdColumn'=>categoryIdColumn, 'parentIdColumn'=>parentIdColumn, 'labelColumns'=>categoryLabelColumns, 'encoding'=>encoding, 'delimiter'=>delimiter, 'enclosure'=>enclosure, 'escape'=>escape, 'lineSeparator'=>lineSeparator}
            return addSourceFile(filePath, sourceId, container, 'hierarchical', 'CSV', params, validate)
        end

        def addResourceFile(filePath, categoryIdColumn, labelColumns, encoding = 'UTF-8', delimiter = ',', enclosure = "\&", escape = "\\\\", lineSeparator = "\\n", sourceId = nil, container = 'products', validate=true, maxLength=23) 
            params = {'referenceIdColumn'=>categoryIdColumn, 'labelColumns'=>labelColumns, 'encoding'=>encoding, 'delimiter'=>delimiter, 'enclosure'=>enclosure, 'escape'=>escape, 'lineSeparator'=>lineSeparator}
            if(sourceId == nil) 
                sourceId = 'resource_' + getSourceIdFromFileNameFromPath(filePath, container, maxLength, true)
            end
            return addSourceFile(filePath, sourceId, container, 'resource', 'CSV', params, validate)
        end



        def setCSVTransactionFile(filePath, orderIdColumn, productIdColumn, customerIdColumn, orderDateIdColumn, totalOrderValueColumn, productListPriceColumn, productDiscountedPriceColumn, productIdField='bx_item_id', customerIdField='bx_customer_id', productsContainer = 'products', customersContainer = 'customers', fformat = 'CSV', encoding = 'UTF-8', delimiter = ',', enclosure = '"', escape = "\\\\", lineSeparator = "\\n",container = 'transactions', sourceId = 'transactions', validate=true) 

            params = {'encoding'=>encoding, 'delimiter'=>delimiter, 'enclosure'=>enclosure, 'escape'=>escape, 'lineSeparator'=>lineSeparator}

            params['file'] = getFileNameFromPath(filePath)
            params['orderIdColumn'] = orderIdColumn
            params['productIdColumn'] = productIdColumn
            params['product_property_id'] = productIdField
            params['customerIdColumn'] = customerIdColumn
            params['customer_property_id'] = customerIdField
            params['productListPriceColumn'] = productListPriceColumn
            params['productDiscountedPriceColumn'] = productDiscountedPriceColumn
            params['totalOrderValueColumn'] = totalOrderValueColumn
            params['orderReceptionDateColumn'] = orderDateIdColumn

            return addSourceFile(filePath, sourceId, container, 'transactions', fformat, params, validate)
        end

        def addSourceFile(filePath, sourceId, container, type, fformat='CSV', params=Array.new, validate=true) 
            if(getLanguages().size==0) 
                raise "trying to add a source before having declared the languages with method setLanguages"
            end
            if(@sources != nil and @sources[container] != nil) 
                @sources[container] = Array.new
            else
              @sources= Hash.new()
              @sourceIdContainers = Hash.new()
            end
            params['filePath'] = filePath
            params['format'] = fformat
             params['type'] = type
            @sources[container] = Hash.new()
            @sources[container][sourceId] = params
            if(validate) 
                validateSource(container, sourceId)
            end
            @sourceIdContainers[sourceId] = container
            return encodesourceKey(container, sourceId)
        end

        def decodeSourceKey(sourceKey) 
            temp = sourceKey
            return temp.split('-')
        end

        def encodesourceKey(container, sourceId) 
            return container + '-' + sourceId
        end

        def getSourceCSVRow(container, sourceId, row=0, maxRow = 2) 
            if(@sources[container][sourceId]['rows'].nil?)
                csv_text = File.read(@sources[container][sourceId]['filePath'])
                csv = CSV.parse(csv_text, :headers => true)
                count = 1;
                @sources[container][sourceId]['rows'] = Array.new
                csv.each do |row|
                    @sources[container][sourceId]['rows'].push(row)
                    count = count+1
                    if( count >= maxRow) 
                        break
                    end
                end
            end
            if(@sources[container][sourceId]['rows'][row] != nil) 
                return @sources[container][sourceId]['rows'][row]
            end
            return nil
        end

        def validateSource(container, sourceId) 
            source = @sources[container][sourceId]
            if(source['format'] == 'CSV') 
                if(source['itemIdColumn'] != nil) 
                    validateColumnExistance(container, sourceId, source['itemIdColumn'])
                end
            end
        end

        def validateColumnExistance(container, sourceId, col) 
            row = getSourceCSVRow(container, sourceId, 0)
            if(row != nil and row.include?col == false) 
                raise "the source 'sourceId' in the container 'container' declares an column 'col' which is not present in the header row of the provided CSV file: " + row.join(',')
            end
        end

        def addSourceIdField(sourceKey, col, fformat, referenceSourceKey=nil, validate=true) 
            id_field = fformat == 'CSV' ? 'bx_id' : 'id'
            addSourceField(sourceKey, id_field, "id", false, col, referenceSourceKey, validate)
        end

        def addSourceTitleField(sourceKey, colMap, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, "bx_title", "title", true, colMap, referenceSourceKey, validate)
        end

        def addSourceDescriptionField(sourceKey, colMap, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, "bx_description", "body", true, colMap, referenceSourceKey, validate)
        end

        def addSourceListPriceField(sourceKey, col, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, "bx_listprice", "price", false, col, referenceSourceKey, validate)
        end

        def addSourceDiscountedPriceField(sourceKey, col, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, "bx_discountedprice", "discounted", false, col, referenceSourceKey, validate)
        end

        def addSourceLocalizedTextField(sourceKey, fieldName, colMap, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, fieldName, "text", true, colMap, referenceSourceKey, validate)
        end

        def addSourceStringField(sourceKey, fieldName, col, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, fieldName, "string", false, col, referenceSourceKey, validate)
        end

        def addSourceNumberField(sourceKey, fieldName, col, referenceSourceKey=nil, validate=true) 
            addSourceField(sourceKey, fieldName, "number", false, col, referenceSourceKey, validate)
        end

        def setCategoryField(sourceKey, col, referenceSourceKey="resource_categories", validate=true) 
            if(referenceSourceKey == "resource_categories") 
                container = decodeSourceKey(sourceKey)[0]
                sourceId = decodeSourceKey(sourceKey)[1]
                referenceSourceKey = encodesourceKey(container, referenceSourceKey)
            end
            addSourceField(sourceKey, "category", "hierarchical", false, col, referenceSourceKey, validate)
        end

        def addSourceField(sourceKey, fieldName, type, localized, colMap, referenceSourceKey=nil, validate=true) 
            container = decodeSourceKey(sourceKey)[0]
            sourceId = decodeSourceKey(sourceKey)[1]
            if(@sources[container][sourceId].present?)
                if(!@sources[container][sourceId]['fields'].present?)
                    @sources[container][sourceId]['fields'] = Hash.new()
                end
            else
                @sources[container][sourceId] = Hash.new
                @sources[container][sourceId]['fields'] = Hash.new()
            end
            @sources[container][sourceId]['fields'][fieldName] = {'type'=>type, 'localized'=>localized, 'map'=>colMap, 'referenceSourceKey'=>referenceSourceKey}
            if(@sources[container][sourceId]['format'] == 'CSV') 
                if(localized && referenceSourceKey == nil) 
                    if(!colMap.kind_of?(Hash))
                        raise "'fieldName': invalid column field name for a localized field (expect an array with a column name for each language array(lang=>colName)): " + YAML::dump(colMap)
                    end
                    getLanguages().each do |lang|

                        if(colMap[lang] == nil)
                            raise "'fieldName': no language column provided for language 'lang' in provided column map): " + YAML::dump(colMap)
                        end
                        if(!colMap[lang].kind_of?(String)) 
                            raise "'fieldName': invalid column field name for a non-localized field (expect a string): " + YAML::dump(colMap)
                        end
                        if(validate) 
                            validateColumnExistance(container, sourceId, colMap[lang])
                        end
                    end
                else 
                    if(!colMap.kind_of?(String)) 
                        raise "'fieldName' invalid column field name for a non-localized field (expect a string): " + YAML::dump(colMap)
                    end
                    if(validate) 
                        validateColumnExistance(container, sourceId, colMap)
                    end
                end
            end
        end

        def setFieldIsMultiValued(sourceKey, fieldName, multiValued = true) 
            addFieldParameter(sourceKey, fieldName, 'multiValued', multiValued ? 'true' : 'false')
        end

        def addSourceCustomerGuestProperty(sourceKey, parameterValue) 
            addSourceParameter(sourceKey, "guest_property_id", parameterValue)
        end

        def addSourceParameter(sourceKey, parameterName, parameterValue) 
            container = decodeSourceKey(sourceKey)[0]
            sourceId = decodeSourceKey(sourceKey)[1]
            if(@sources[container][sourceId]== nil) 
                raise "trying to add a source parameter on sourceId 'sourceId', container 'container' while this source doesn't exist"
            end
            @sources[container][sourceId][parameterName] = parameterValue
        end

        def addFieldParameter(sourceKey, fieldName, parameterName, parameterValue) 
            container = decodeSourceKey(sourceKey)[0]
            sourceId = decodeSourceKey(sourceKey)[1]
            if(@sources[container][sourceId]['fields'][fieldName] == nil) 
                raise s"trying to add a field parameter on sourceId 'sourceId', container 'container', fieldName 'fieldName' while this field doesn't exist"
            end
            if(@sources[container][sourceId]['fields'][fieldName]['fieldParameters']== nil) 
                @sources[container][sourceId]['fields'][fieldName]['fieldParameters'] = Array.new
            end
            @sources[container][sourceId]['fields'][fieldName]['fieldParameters'][parameterName] = parameterValue
        end


        def setFtpSource(sourceKey, host="di1.bx-cloud.com", port=21, user=nil, password=nil, remoteDir = '/sources/production', protocol=0, type=0, logontype=1,
                                     timezoneoffset=0, pasvMode='MODE_DEFAULT', maximumMultipeConnections=0, encodingType='Auto', bypassProxy=0, syncBrowsing=0) 

            if(user==nil)
                user = @bxClient.getAccount(false)
            end

            if(password==nil)
                password = @bxClient.getPassword()
            end

            params = Array.new
            params['Host'] = host
            params['Port'] = port
            params['User'] = user
            params['Pass'] = password
            params['Protocol'] = protocol
            params['Type'] = type
            params['Logontype'] = logontype
            params['TimezoneOffset'] = timezoneoffset
            params['PasvMode'] = pasvMode
            params['MaximumMultipleConnections'] = maximumMultipeConnections
            params['EncodingType'] = encodingType
            params['BypassProxy'] = bypassProxy
            params['Name'] = user + " at " + host
            params['RemoteDir'] = remoteDir
            params['SyncBrowsing'] = syncBrowsing
            container = decodeSourceKey(sourceKey)[0]
            sourceId = decodeSourceKey(sourceKey)[1]
            @ftpSources[sourceId] = params
        end

        def getXML() 

            xml = Builder::XmlMarkup.new( :target => $stdout, :indent => 2 )
            xml.instruct! :xml, :version=>"1.0"
            #languages
            xml.root do
                xml.languages do
                    getLanguages().each do | lang |
                        xml.language( lang, 'id' => lang )
                    end
                end

                #containers
                xml.containers do
                    @sources.each do | containerName , containerSources |
                        xml.container(  'id' => containerName, 'type' => containerName ) do
                            # adding sources
                            xml.sources do
                                # Adding Source
                                containerSources.each do |sourceId , sourceValues|

                                    if(sourceValues['additional_item_source'] != nil)
                                        if(@ftpSources[sourceId] != nil)
                                            xml.source("id" => sourceId, "type" => sourceValues['type'] ,'additional_item_source'=> sourceValues['additional_item_source']) do
                                                xml.location('type'=>'ftp')
                                                xml.ftp('name'=>'ftp')
                                                # @ftpSources[sourceId].each do |ftpPn , ftpPv|
                                                #     ftp->ftpPn = ftpPv
                                                # end
                                            end
                                        else
                                            #To check Below line
                                            xml.source('id' => sourceId, 'type' => sourceValues['type'] ,'additional_item_source'=> sourceValues['additional_item_source'])
                                        end
                                    else
                                        if(@ftpSources == nil)
                                            @ftpSources = Hash.new()
                                        end
                                        if(@ftpSources[sourceId] != nil)
                                            xml.source('id' => sourceId, 'type' => sourceValues['type'])
                                            xml.location('type'=>'ftp')
                                            xml.ftp('name'=>'ftp')
                                        else
                                            xml.source('id' => sourceId, 'type' => sourceValues['type'])
                                        end
                                    end





                                    sourceValues['file'] = getFileNameFromPath(sourceValues['filePath'])
                                    if(sourceValues['format'] == 'CSV')
                                        parameters = {
                                            'file'=>false,
                                            'format'=>'CSV',
                                            'encoding'=>'UTF-8',
                                            'delimiter'=>',',
                                            'enclosure'=>'"',
                                            'escape'=>'\\\\',
                                            'lineSeparator'=>"\\n"
                                        }
                                    elsif(sourceValues['format'] == 'XML')
                                        parameters = {
                                            'file'=>false,
                                            'format'=> sourceValues['format'],
                                            'encoding'=> sourceValues['encoding'],
                                            'baseXPath'=> sourceValues['baseXPath']
                                        }
                                    end

                                    case sourceValues['type']
                                        when 'item_data_file'
                                            parameters['itemIdColumn'] = false

                                        when 'hierarchical'
                                            parameters['referenceIdColumn'] = false
                                            parameters['parentIdColumn'] = false
                                            parameters['labelColumns'] = false

                                        when 'resource'
                                            parameters['referenceIdColumn'] = false
                                            parameters['itemIdColumn'] = false
                                            parameters['labelColumns'] = false
                                            sourceValues['itemIdColumn'] = sourceValues['referenceIdColumn']

                                        when 'transactions'
                                            parameters = sourceValues
                                            parameters.delete('filePath')
                                            parameters.delete('type')
                                            parameters.delete('product_property_id')
                                            parameters.delete('customer_property_id')
                                    end
                                    parameters.each do |parameter , defaultValue|
                                        value = sourceValues[parameter] != nil ? sourceValues[parameter] : defaultValue
                                        if(value == false)
                                            raise "source parameter 'parameter' required but not defined in source id 'sourceId' for container 'containerName'"
                                        end


                                        if(value.kind_of?(Array))
                                            if(sourceValues['type'] == 'transactions')
                                                if(parameter =='productIdColumn')
                                                    xml.tag!(parameter , 'product_property_id'=>  sourceValues['product_property_id']) do
                                                        value.each do |language , languageColumn|
                                                            xml.language('name' => language, 'value' => languageColumn )
                                                        end
                                                   end
                                                elsif(parameter == 'customerIdColumn' && sourceValues['guest_property_id'] != nil)
                                                    xml.tag!(parameter ,'customer_property_id'=> sourceValues['customer_property_id'] ,'guest_property_id'=>sourceValues['guest_property_id']) do
                                                        value.each do |language , languageColumn|
                                                            xml.language('name' => language, 'value' => languageColumn )
                                                        end
                                                   end
                                                elsif(parameter == 'customerIdColumn')
                                                    xml.tag!(parameter ,'customer_property_id'=> sourceValues['customer_property_id']) do
                                                        value.each do |language , languageColumn|
                                                            xml.language('name' => language, 'value' => languageColumn )
                                                        end
                                                   end
                                                else
                                                    xml.tag!(parameter) do
                                                        value.each do |language , languageColumn|
                                                            xml.language('name' => language, 'value' => languageColumn )
                                                        end
                                                   end
                                                end
                                            else
                                               xml.tag!(parameter) do
                                                    value.each do |language , languageColumn|
                                                        xml.language('name' => language, 'value' => languageColumn )
                                                    end
                                               end
                                           end
                                        else
                                            xml.tag!(parameter,'value'=>value)
                                        end

                                    end
                                end

                            end
                            #Adding Properties
                            xml.properties do
                                #Adding Properties
                              containerSources.each do |sourceId , sourceValues|
                                  if(sourceValues['fields'] != nil)
                                        sourceValues['fields'].each do |fieldId , fieldValues|
                                            xml.property('id'=>fieldId, 'type'=>fieldValues['type']) do
                                                xml.transform() do
                                                    #xml.logic('source'=> sourceId);
                                                    referenceSourceKey = fieldValues['referenceSourceKey'] != nil ? fieldValues['referenceSourceKey'] : nil
                                                    logicType = ((sourceValues['format'] == 'XML') ? "xpath" : (referenceSourceKey == nil ? 'direct' : 'reference'))
                                                    if(logicType == 'direct')
                                                        if(fieldValues['fieldParameters'] != nil)
                                                            fieldValues['fieldParameters'].each do |parameterName , parameterValue|
                                                                case parameterName
                                                                    when  'pc_fields'
                                                                    when 'pc_tables'
                                                                        logicType = 'advanced'
                                                                end
                                                            end
                                                        end
                                                    end
                                                   # logic->addAttribute('type', logicType);
                                                    if(fieldValues['map'].kind_of?(Hash))
                                                        xml.logic('source'=> sourceId, 'type' => logicType) do
                                                            getLanguages().each do |lang|
                                                                xml.field('column'=> fieldValues['map'][lang], 'language'=> lang)
                                                            end
                                                        end
                                                    else
                                                        xml.logic('source'=> sourceId, 'type' => logicType) do
                                                            xml.field('column'=> fieldValues['map'])
                                                        end
                                                    end

                                                    if (referenceSourceKey)
                                                      xml.params do
                                                        referenceSourceId = decodeSourceKey(referenceSourceKey)[1]
                                                        xml.referenceSource('value' => referenceSourceId)
                                                        if(fieldValues['fieldParameters'] != nil)
                                                          fieldValues['fieldParameters'].each do |parameterName , parameterValue|
                                                            xml.fieldParameter('name' => parameterName, 'value' => parameterValue)
                                                          end
                                                        end
                                                      end
                                                    elsif (fieldValues['fieldParameters'] != nil)
                                                      xml.params do
                                                        fieldValues['fieldParameters'].each do |parameterName , parameterValue|
                                                          xml.fieldParameter('name' => parameterName, 'value' => parameterValue)
                                                        end
                                                      end
                                                    end
                                                end


                                            end
                                        end
                                  end
                                end
                            end
                        end
                    end
                end
            end
        end


        def callAPI(fields, url, temporaryFilePath=nil, timeout=60)
        
            uri = URI(url)
            if uri.scheme == "https"
              uri.port = 443
            end
            http = Net::HTTP.new(uri.host, uri.port)
            #http.use_ssl = true
            request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})

            request.form_data = fields # SOME JSON DATA
           # puts fields['xml'];

            #request.body = fields # SOME JSON DATA
            response = http.request(request)
            checkResponseBody(response, url)
        end

        def getError(responseBody) 
            return responseBody
        end

        def checkResponseBody(responseBody, url) 
            if(responseBody == nil) 
                raise "API response of call to url is empty string, this is an error!"
            end
            value = ActiveSupport::JSON.decode(responseBody.body)
            if(responseBody.body['token']== nil)

                if(value['changes']== nil)
                    raise responseBody.body
                end
            end
            return value
        end

        def pushDataSpecifications(ignoreDeltaException=false) 

            if(!ignoreDeltaException && @isDelta)
                raise "You should not push specifications when you are pushing a delta file. Only do it when you are preparing full files. Set method parameter ignoreDeltaException to true to ignore this exception and publish anyway."
            end
            doc = File.open('sample_data/properties.xml') { |f| Nokogiri::XML(f) }
            fields = {
                'username' => @bxClient.getUsername(),
                'password' => @bxClient.getPassword(),
                'account' => @bxClient.getAccount(false),
                'owner' => @owner,
                #'xml' => doc
                'xml' => getXML()
            }

            url = @host + URL_XML;
            return callAPI(fields, url)
        end

        def checkChanges
            publishOwnerChanges(false)
        end

        def publishChanges
            publishOwnerChanges(true)
        end

        def publishOwnerChanges(publish=true) 
            if(@isDev) 
                publish = false
            end
            fields = {
                'username' => @bxClient.getUsername(),
                'password' => @bxClient.getPassword(),
                'account' => @bxClient.getAccount(false),
                'owner' => @owner,
                'publish' => (publish ? 'true' : 'false')
            }

            url = @host + URL_PUBLISH_CONFIGURATION_CHANGES
            return callAPI(fields, url)
        end

        def verifyCredentials 
            fields = {
                'username' => @bxClient.getUsername(),
                'password' => @bxClient.getPassword(),
                'account' => @bxClient.getAccount(false),
                'owner' => @owner
            }

            url = host + URL_VERIFY_CREDENTIALS
            return callAPI(fields, url)
        end

        def alreadyExistingSourceId(sourceId, container) 
            return @sources[container][sourceId] != nil
        end

        def getUnusedSourceIdPostFix(sourceId, container) 
            postFix = 2;
            @sources[container].each do |sid , values| 
                if(sid.index(sourceId) == nil) 
                    sid[sourceId] =  ''
                    count = sid
                    if(count >= postFix) 
                        postFix = count + 1
                    end
                end
            end
            return postFix
        end

        def getSourceIdFromFileNameFromPath(filePath, container, maxLength=23, withoutExtension=false) 
            sourceId = getFileNameFromPath(filePath, withoutExtension)
            shortened = false
            if(sourceId.length > maxLength) 
                sourceId = sourceId[ 0, maxLength]
                shortened = true
            end
            if(alreadyExistingSourceId(sourceId, container)) 
                if(!shortened) 
                    raise 'Synchronization failure: Same source id requested twice "' + filePath + '". Please correct that only created once.'
                end
                postFix = getUnusedSourceIdPostFix(sourceId, container)
                sourceId = sourceId + postFix
            end
            return sourceId
        end

        def getFileNameFromPath(filePath, withoutExtension=false) 
            parts = filePath.split('/')
            file = parts[parts.size-1]
            if(withoutExtension) 
                parts = file.split('.')
                return parts[0]
            end
            return file
        end

        def getFiles 
            files = Hash.new
            @sources.each do | container , containerSources|
                containerSources.each do |sourceId , sourceValues| 
                    if(@ftpSources.key?(sourceId) )
                        next
                    end
                    if(!sourceValues.key?('file'))
                        sourceValues['file'] = getFileNameFromPath(sourceValues['filePath'])
                    end
                    files[sourceValues['file']] = sourceValues['filePath']
                end
            end
            return files
        end

        def createZip(temporaryFilePath=nil, nname='bxdata.zip')
        
            if(temporaryFilePath === nil) 
                temporaryFilePath = Dir.tmpdir() + '/bxclient'
            end

            if (temporaryFilePath != "" && !File.exist?(temporaryFilePath)) 
                Dir.mkdir(temporaryFilePath)
            end

            zipFilePath = temporaryFilePath + '/' + nname;

            if (File.file?(zipFilePath)) 
                FileUtils.rm(zipFilePath)
            end

            files = getFiles()

          
          
            Zip::File.open(zipFilePath, Zip::File::CREATE) do |zipfile|
                # foreach (files as f => filePath) 
                #     if (!zip->addFile(filePath, f)) 
                #         throw new \Exception(
                #             'Synchronization failure: Failed to add file "' .
                #             filePath . '" to the zip "' .
                #             name . '". Please try again.'
                #         );
                #     }
                # }

                # if (!zip->addFromString ('properties.xml', this->getXML())) 
                #     throw new \Exception(
                #         'Synchronization failure: Failed to add xml string to the zip "' .
                #         name . '". Please try again.'
                #     );
                # }

                # if (!zip->close()) 
                #     throw new \Exception(
                #         'Synchronization failure: Failed to close the zip "' .
                #         name . '". Please try again.'
                #     );
                # }
              files.each do |f, filePath|
                # Two arguments:
                # - The name of the file as it will appear in the archive
                # - The original file, including the path to find it
                zipfile.add(filePath, File.join('sample_data', f))
              end
              zipfile.get_output_stream(zipFilePath) { |f| f.write "myFile contains just this" }
            end

           
            return zipFilePath
        end

        def pushData(temporaryFilePath=nil, timeout=60) 

            zipFile = createZip(temporaryFilePath)
            fields = {
                'username' => @bxClient.getUsername(),
                'password' => @bxClient.getPassword(),
                'account' => @bxClient.getAccount(false),
                'owner' => @owner,
                'dev' => (@isDev ? 'true' : 'false'),
                'delta' => (@isDelta ? 'true' : 'false'),
                'data' => zipFile+"type=application/zip"
               # 'data' => getCurlFile(zipFile, "application/zip")
            }

            url = @host + URL_ZIP
            return callAPI(fields, url, temporaryFilePath, timeout)
        end

        # def getCurlFile(filename, type)
        
        #     begin 
        #         if (class_exists('CURLFile')) 
        #             return new \CURLFile(filename, type);
        #         }
        #     } catch(\Exception e) }
        #     return "@filename;type=type";
        # end

        def getTaskExecuteUrl(taskName) 
            return @host + URL_EXECUTE_TASK + '?iframeAccount=' + @bxClient.getAccount() + '&task_process=' + taskName
        end

        def publishChoices(isTest = false, taskName="generate_optimization") 

            if(@isDev) 
                taskName = taskName + '_dev'
            end
            if(@isTest) 
                taskName = taskName +  '_test'
            end
            url = getTaskExecuteUrl(taskName)
            document = open(url) { |f| f.read }
            # File.read(url)
        end

        def prepareCorpusIndex(taskName="corpus") 
            url = getTaskExecuteUrl(taskName)
            document = open(url) { |f| f.read }
        end

        def prepareAutocompleteIndex(fields, taskName="autocomplete") 
            url = getTaskExecuteUrl(taskName)
            document = open(url) { |f| f.read }
        end
    end
end