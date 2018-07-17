# boxalino Client SDK in Ruby

The Boxalino Client SDK provides a simple and efficient usage of Boxalino Search & Recommendations services (based on the p13n Thrift client libraries as separately provided in respective git-hub repositories) and to Boxalino Data Intelligence especially for Data Synchronization (define the structure of your data, push and publish your data structure configuration, push data in dev/prod and full/delta to Boxalino).

The Boxalino Client SDK are particularly interesting for integrators of Boxalino technologies and provides the following advantages compare to using the underlying API directly.

## Key advantages

1. Very easy examples (such as frontend search basic) to start from (step by step)
2. Many examples to understand each functionality individually
3. Very little amount of code to write and to maintain (all the hard stuff is done in the client)
4. Very well adapted for most MVC environment where the full requests / responses are not created all at the same place (easy to do if keeping the instance of BxClient as static)
5. Many embedded logics not to worry about anymore (e.g.: search corrections directly active and integrated, no need to worry about it, a simple method returns if the query was corrected or not as indication)
6. No need to create your XML data specification file by yourself anymore (provide the links to your data CSV and simple indications of which csv columsn to put in which fields)
7. Easy to test data correctness automatically before sending your data to Boxalino Data Intelligence (client can check if there is any mis-match with your column to field specfications)
8. Easy to interact with all the APIs (all calls are embedded in the client and you simply need to call simple to use methods of the client instance)
9. Very easy to understand error messages and to know what to do (error messages often even indicates where it is most likely you should solve the problem, like in the case of issues with SSL certificates to get the connection)
10. Easy to print the request Thrift object and send it to Boxalino for any support request

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'BoxalinoPackage', git:'https://github.com/boxalino/boxalino-client-sdk-ruby'
```

And then execute:

    $ bundle install


## Usage

```ruby
	BoxalinoPackage::BxClient.new('csharp_unittest' , 'csharp_unittest' , 'domain.com')
```

## Data Indexing examples

provided in a good order to learn them step by step!

###### backend data basic:
In this example, we take a very simple CSV file with product data, generate the specifications, load them, publish them and push the data to Boxalino Data Intelligence.

###### backend data debug xml:
In this example, we take a very simple CSV file with product data, generate the specifications and print them in xml format.

###### backend data categories:
In this example, we take a very simple CSV file with product and categories data (and the link between them), generate the specifications, load them, publish them and push the data to Boxalino Data Intelligence.

###### backend data split field values:
In this example, we take a very simple CSV file with product data, generate the specifications of a field splitting it's values (field provided as coma separated values in one csv cell), load them, publish them and push the data to Boxalino Data Intelligence.

###### backend data resource:
In this example, we take a very simple CSV file with product data a reference data (and the link between them), generate the specifications, load them, publish them and push the data to Boxalino Data Intelligence.

###### backend data customers:
In this example, we take very simple CSV files with product data and customer data, generate the specifications, load them, publish them and push the data to Boxalino Data Intelligence.

###### backend data transactions:
In this example, we take very simple CSV files with product data, customer data and transactions historical data generate the specifications, load them, publish them and push the data to Boxalino Data Intelligence.

## Search examples

provided in a good order to learn them step by step!

###### frontend search basic:
In this example, we make a simple search query, get the search results and print their ids including a total counter.

###### frontend search return fields:
In this example, we make a simple search query, defined additional fields to be returned for each reserult, get the search results and print their field values.

###### frontend search 2nd page:
In this example, we make a simple search query, get the second page of search results and print their ids.

###### frontend search sort field:
In this example, we make a simple search query with a special sort order and get the first search results according to this order.

###### frontend search facet:
In this example, we make a simple search query, request a facet and get the search results and print the facet values and counter.

###### frontend search facet category:
In this example, we make a simple search query, request a facet and get the search results and print the facet values and counter of categories.

###### frontend search facet price:
In this example, we make a simple search query, request a facet and get the search results and print the facet values and counter for price ranges.

###### frontend search corrected:
In this example, we make a simple search query with a typo, get the search results and print the corrected query and the search results ids.

###### frontend search sub phrases:
In this example, we make a simple search query containing two keywords which both provides search results alone, but none together. Then we show the two sub-phrases groups to let the user chose to search for one or the other.

###### frontend search filter:
In this example, we make a simple search query, add a filter and get the search results and print their ids.

###### frontend search filter advanced:
In this example, we make a simple search query, add a more advanced filters with 2 fields with values and an or conditions between them and get the search results and print their ids.

###### frontend search debug request:
In this example, we make a simple search query and we print the request object. This is very helpful to understand what could be the cause of a problem. Please always include the printout of this object in your support request to Boxalino.

## Search autocomplete examples

provided in a good order to learn them step by step!

###### frontend search autocomplete basic:
In this example, we make a simple search autocomplete query, get the textual search suggestions.

###### frontend search autocomplete items:
In this example, we make a simple search autocomplete query, get the textual search suggestions and the item suggestions for each textual suggestion and globally.

###### frontend search autocomplete items bundled:
In this example, we make several search autocomplete queries, and for each get the textual search suggestions and the item suggestions for each textual suggestion and globally.

###### frontend search autocomplete property:
In this example, we show how to get autocomplete response on a property (to see what property value start with the query as prefix and how many search result they return if searched)

## Recommendations examples

provided in a good order to learn them step by step!

###### frontend recommendations similar:
In this example, we make a simple recommendation example to display similar recommendations on a product detail page.

###### frontend recommendations similar complementary:
In this example, we make a simple recommendation example to display both similar and complementary recommendations on a product detail page

###### frontend recommendations basket:
In this example, we make a simple recommendation example to display cross selling recommendations on a basket page.

## Contact us!

If you have any question, just contact us at support@boxalino.com

