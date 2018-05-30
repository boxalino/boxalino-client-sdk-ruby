module BoxalinoPackage
	require 'BoxalinoPackage/BxRequest'
	class BxSearchRequest 
		def initialize(language, queryText, max=10, choiceId=nil)
		    if (choiceId == nil) 
				choiceId = 'search'
			end
			BxRequest.new(language, choiceId, max, 0)
			BxRequest.setQueryText(queryText)
		end
		
	end
end