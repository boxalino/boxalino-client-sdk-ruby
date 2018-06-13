module BoxalinoPackage
	class BxSortFields
		require 'BoxalinoPackage/p13n_types'
		@sorts = Hash.new

	    def  initialize(field=nil, reverse=false)
				@sorts = Hash.new
				if(field)
					push(field, reverse)
				end
	    end

	    #/**
	    # * @param $field name od field to sort by (i.e. discountedPrice / title)
	    # * @param $reverse true for ASC, false for DESC
	    # */
	    def  push(field, reverse=false)
	    
	        @sorts[field] = reverse

	    end

	    def getSortFields
				if(@sorts.nil?)
					return Array.new

				end
			return @sorts.keys
	    end
		
		def isFieldReverse(field) 
			if(@sorts.key?(field) && @sorts[field])
				return true;
			end
			return false;
		end
		
		def getThriftSortFields
			@sortFields = Array.new
			getSortFields().each do |field|
				@sortFields.push(SortField.new({'fieldName' => field,'reverse' => isFieldReverse(field)}))
			end
			return @sortFields
		end
		
	end
end