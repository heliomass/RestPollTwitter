#
# Module to get an update from a Twitter account
#
# Information on how to produce a signature is given here:
# https://dev.twitter.com/docs/auth/creating-signature
#
# Information on how to produce a request is given here:
# https://dev.twitter.com/docs/auth/authorizing-request
#
# If you're using this in your own project, follow the
# example in Rest__test_modules.
#

# Initialisation checks
Rest__errors=0
which tclsh > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo 'TCL Shell is required.' >&2
	Rest__errors=1
fi
which perl > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo 'Perl is required.' >&2
	Rest__errors=1
fi
which curl > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo 'cURL is required.' >&2
	Rest__errors=1
fi
if [ $Rest__errors -ne 0 ]; then
	exit 1
fi
unset Rest_errors

# Initialised?
Rest__init_status=0

# Stores the full set of arguments for the request
Rest__request_args=

# Has the current request been used?
Rest__request_used=1

#
# Initialises the module.
#
# Input parameters - NONE
#
# Output Parameters - NONE
#
Rest__init () {

	#  Already initialised
	if [ $Rest__init_status -gt 0 ]; then
		return 1
	fi

	# Source the config. It should specify the following:
	#
	# Rest__consumer_key
	# Rest__consumer_secret
	# Rest__access_token
	# Rest__access_token_secret
	#
	source $1

	# Initialised!
	Rest__init_status=1

	return 0

}

#
# Initialises a fresh request
#
# Input parameters - NONE
#
# Output Parameters - NONE
#
Rest__initialise_request () {

	# Abort if not initialised
	if [ $Rest__init_status -eq 0 ]; then
		echo 'Rest__initialise_request: Module not initialised.' >&2
		return 1
	fi

	Rest__request_args=
	Rest__request_used=0

	return 0

}

#
# Makes a request
#
# Input Parameters:
#    $1 - _api_url - The URL of the Rest API
#
# Output Parameters:
#    $2 - _response        - The full response from the request
#
Rest__make_request () {

	# Input Parameters
	local _api_url=$1

	# Other Local Variables
	local _basic_args
	local _oauth_timestamp
	local _oauth_nonce
	local _oauth_signature
	local _req_header
	local _cmd
	local _response

	# Abort if not initialised
	if [ $Rest__init_status -eq 0 ]; then
		echo 'Rest__make_request: Module not initialised.' >&2
		return 1
	fi

	# Abort if a new request has not been set up
	if [ $Rest__request_used -eq 1 ]; then
		echo 'Rest__make_request: Error! A new request is required.' >&2
		return 1
	fi

	# Mark this request as used, even if it fails.
	Rest__request_used=1

	# Sort the arguments
	Rest__sort_arguments

	# Remember the basic selection of arguments
	_basic_args=$Rest__request_args

	# Get a timestamp for this request
	_oauth_timestamp=$(date +%s)

	# Generate _oauth_nonce (a unique token generated by this
	# server to prove the request is unique) using the host
	# name and the timestamp
	_oauth_nonce=$(eval "echo $(uname -n)_${_oauth_timestamp} | $Config__md5_cmd")

	# Add the extra arguments required by the final request
	Rest__add_argument 'oauth_consumer_key' $Rest__consumer_key
	Rest__add_argument 'oauth_nonce' $_oauth_nonce
	Rest__add_argument 'oauth_signature_method' 'HMAC-SHA1'
	Rest__add_argument 'oauth_timestamp' $_oauth_timestamp
	Rest__add_argument 'oauth_token' $Rest__access_token
	Rest__add_argument 'oauth_version' '1.0'

	# Sort arguments again
	Rest__sort_arguments

	# Make the OAuth signature
	Rest__make_oauth_signature "$Rest__request_args" 'GET' "$_api_url" _oauth_signature

	# Make the header for the request
	_req_header="Authorization: OAuth oauth_consumer_key=\"${Rest__consumer_key}\", oauth_nonce=\"${_oauth_nonce}\", oauth_signature=\"${_oauth_signature}\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"${_oauth_timestamp}\", oauth_token=\"${Rest__access_token}\", oauth_version=\"1.0\""

	# Put the response in a file
	_response_file=$(mktemp)
	touch $_response_file

	# Build the curl command
	_cmd="curl --get '$_api_url' --data '$_basic_args' --header '$_req_header' --include --insecure > $_response_file"

	# Make the request and store the response
	eval $_cmd

	# The status
	_response_status=$(cat $_response_file | grep 'status' | head -n 1 | sed 's/^status: //' | sed 's/ OK.*$//')
	if [[ $_response_status == '' ]]; then
		_response_status=500
	fi

	# The actual response
	_response=$(cat $_response_file | tail -n 1)

	# Return the response as the second input arg.
	eval "$2=$(echo -n '${_response}')"

	eval "$3=${_response_status}"

}

#
# Adds an argument / value pair to the request
#
# Input Parameters:
#    $1 - _arg - Arg name
#    $2 - _val - Value associated with _arg
#
# Output Parameters - NONE
#
Rest__add_argument () {

	# Input Parameters
	local _arg=$1
	local _val=$2

	# Abort if not initialised
	if [ $Rest__init_status -eq 0 ]; then
		echo 'Rest__add_argument: Module not initialised.' >&2
		return 1
	fi

	# URL encode the value.
	# We assume that the argument name isn't idiotic.
	# We also assume no spaces in the value (which may be idiotic of me to assume that)

	#_val=$(Rest__url_encode $_val)
	Rest__url_encode $_val _val

	if [[ $Rest__request_args != '' ]]; then
		Rest__request_args="${Rest__request_args}&"
	fi

	Rest__request_args="${Rest__request_args}${_arg}=${_val}"

	return 0

}

#
# Sort the arguments into alphabetical order
#
# Input parameters - NONE
#
# Output Parameters - NONE
#
Rest__sort_arguments () {

	# Abort if not initialised
	if [ $Rest__init_status -eq 0 ]; then
		echo 'Rest__sort_arguments: Module not initialised.' >&2
		return 1
	fi

	# TCL rocks
	Rest__request_args=$(echo "puts -nonewline [join [lsort [split $Rest__request_args {&}]] {&}]" | tclsh)

	return 0

}

#
# URL encodes a string
#
# Input Parameters:
#    $1 - _string - String which needs to be URL encoded
#
# Output Parameters:
#    $2 - _string_enc - The encoded string
#
Rest__url_encode () {

	# Input Parameters
	local _string="$1"

	# Other Local Variables
	local _string_enc

	# Abort if not initialised
	if [ $Rest__init_status -eq 0 ]; then
		echo 'Rest__url_encode: Module not initialised.' >&2
		return 1
	fi

	# Perl sucks
	_string_enc=$(perl -MURI::Escape -e "print uri_escape('$_string');" "$2")
	_string_enc=$(printf "%s" $_string_enc)
	eval "$2=$_string_enc"

	return 0

}


#
# Creates an oauth signature.
#
# Usage:
#   make_oauth_signature parameters url_encoded_parameters method url
#   (note, the parameters must be ordered alphabetically,
#   method must be in upper case (POST or GET),
#   url must be URL encoded)
#
# Input Parameters:
#    $1 - _parameters - Args for the request
#    $2 - _method     - Request method (GET or POST)
#    $3 - _url        - URL of the Rest API
#
# Output Parameters
#    $4 - _signature  - The finalised OAUTH signature
#
Rest__make_oauth_signature () {

	# Input Parameters
	local _parameters=$1
	local _method=$2
	local _url=$3

	# Other Local Variables
	local _encoded_url
	local _encoded_parameters
	local _base_string
	local _consumer_secret_enc
	local _access_token_secret_enc
	local _signing_key
	local _signature

	# Abort if not initialised
	if [ $Rest__init_status -eq 0 ]; then
		echo 'Rest__make_oauth_signature: Module not initialised.' >&2
		return 1
	fi

	Rest__url_encode "$_url" _encoded_url
	Rest__url_encode "$_parameters" _encoded_parameters

	# Form the base string now
	_base_string="${_method}&${_encoded_url}&${_encoded_parameters}"

	Rest__url_encode "$Rest__consumer_secret" _consumer_secret_enc
	Rest__url_encode "$Rest__access_token_secret" _access_token_secret_enc

	# Get the signing key
	_signing_key="${_consumer_secret_enc}&${_access_token_secret_enc}"

	# Calculate the signature itself
	_signature=$(echo -n "$_base_string" | openssl sha1 -hmac "$_signing_key" -binary | base64)

	# URL encode the signature
	#_signature=$(Rest__url_encode "$_signature")
	Rest__url_encode "$_signature" _signature

	# Return the response as the second input arg.
	eval "$4=$_signature"

	return 0

}
