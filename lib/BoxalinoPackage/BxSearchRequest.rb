module BoxalinoPackage
	require 'BoxalinoPackage/BxRequest'
	class BxSearchRequest < BxRequest
		def initialize(language, queryText, max=10, choiceId=nil)
		    if (choiceId == nil) 
				choiceId = 'search'
			end
			if(queryText.nil?)
			    choiceId = 'navigation'
			end
			 _bxRequest = super(language, choiceId, max, 0)
			 setQueryText(queryText)
		end
		
	end
end