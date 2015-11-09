# Rest Poll Twitter
## Description
Rest Poll Twitter is a crude library written in Bash which will enable you to get the n most recent updates from a given Twitter account.

I wrote this as a module for another project, and I've uploaded it to my GitHub account for prosperity. Could be useful if you've a dirty bash script that needs to hit Twitter for something.

## Dependancies
You will need both the TCL Shell (`tclshell`), the `perl` command installed as well as cURL.

You will also need a Twitter account you can use to authorise requests. To learn how to produce a signature [click here](https://dev.twitter.com/docs/auth/creating-signature). You can read more about producing a request [here](https://dev.twitter.com/docs/auth/authorizing-request) if you're interested to know how things are supposed to work under the hood and what steps this script is trying to achieve.

## Usage
You will need to specify a configuration file with the credentials for a valid Twitter account. Your config file should look exactly like this:

```
Rest__consumer_key='<your_consumer_key>'
Rest__consumer_secret='<your_consumer_secret>'
Rest__access_token='<your_access_token>'
Rest__access_token_secret='<your_access_token_secret>'
```
In your own script, if you wanted to retrieve the latest Tweet from [my Twitter account](https://twitter.com/heliomass), you'd do something like this:

```Shell
# Step 1: Source the library
source "<path_to_library>/rest_poll_twitter.sh"

# Step 2: Initialise the module
# (only needs to be done once)
Rest__init "<location_of_your_config_file>.conf"

# Step 3: Initialise a new request
# (needs to be done once for each request, even if a request fails)
Rest__initialise_request

# Step 4: Add some arguments
# If the below were the end of a URL, it would look like:
# ?count=1&exclude_replies=false&include_rts=true&screen_name=Heliomass
Rest__add_argument 'count' '1'
Rest__add_argument 'exclude_replies' 'false'
Rest__add_argument 'include_rts' 'true'
Rest__add_argument 'screen_name' 'Heliomass'

# Set 5: Set the URL of the API we want to hit
# (in this case, user timelines)
local _api_url='https://api.twitter.com/1.1/statuses/user_timeline.json'

# Step 6: Make the request to a specified API URL, and store the response in
# a new variable _test_response
local _test_response
Rest__make_request $_api_url _test_response

# We're done! Display the results of our test.

# Print the arguments
echo $Rest__request_args

# Display the response
echo $_test_response
```