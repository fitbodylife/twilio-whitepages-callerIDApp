require 'rubygems'
require 'sinatra'
require 'twilio-ruby'

disable :protection

# put your default Twilio Client name here, for when a phone number isn't given
default_client = "hales"
# Add a Twilio phone number or number verified with Twilio as the caller ID
caller_id   = ENV['twilio_caller_id']
account_sid = ENV['twilio_account_sid']
auth_token  = ENV['twilio_auth_token']
appsid      = ENV['twilio_app_id']
api_key     = ENV['twilio_api_key']
api_secret  = ENV['twilio_api_secret']
sync_sid    = ENV['twilio_sync_service_sid']

get '/' do
    client_name = params[:client]
    if client_name.nil?
        client_name = default_client
    end

    capability = Twilio::Util::Capability.new account_sid, auth_token
    # Create an application sid at twilio.com/user/account/apps and use it here/above
    capability.allow_client_outgoing appsid
    capability.allow_client_incoming client_name
    token = capability.generate
    erb :index, :locals => {:token => token, :client_name => client_name, :caller_id=> caller_id}
end

# Generate a token for use in our app
get '/token' do
  # Get the user-provided ID for the connecting device
  puts "In token"
  device_id = params['device']
  puts "Received token, " device_if
  # Create a random username for the client
  identity = 'twilioTest'
  # Create a unique ID for the currently connecting device
  endpoint_id = "TwilioDemoApp:#{identity}:#{device_id}"
  # Create an Access Token for the app
  puts "Created endpoint ID, " endpoint_id
  token = Twilio::Util::AccessToken.new account_sid, api_key, api_secret, identity
  # Create app grant for out token
  puts "token created"
  grant = Twilio::Util::AccessToken::SyncGrant.new
  puts "Grant created"
  grant.service_sid = sync_sid
  grant.endpoint_id = endpoint_id
  token.add_grant grant

  # Generate the token and send to the client
  json :identity => identity, :token => token.to_jwt
end

post '/dial' do
    #determine if call is inbound
    number = params[:PhoneNumber]

    response = Twilio::TwiML::Response.new do |r|
        # Should be your Twilio Number or a verified Caller ID
        r.Dial :callerId => caller_id do |d|
            # Test to see if the PhoneNumber is a number, or a Client ID. In
            # this case, we detect a Client ID by the presence of non-numbers
            # in the PhoneNumber parameter.
            if /^[\d\+\-\(\) ]+$/.match(number)
                d.Number(CGI::escapeHTML number)
            else
                d.Client number
            end
        end
    end
    response.text
end

#this will be called from a Twilio voice URL
#for inbound calls, dial the default_client
post '/inbound' do

    from = params[:From]=
    addOnData = params[:AddOns]
    client = Twilio::REST::Client.new(account_sid, auth_token)
    # Sending the add on data through the web socket
    service = client.preview.sync.services('sync_sid')
    response = service.documents.create(
      unique_name: "TwilioChannel",
      data: addOnData)
    # Dials the default_client
    response = Twilio::TwiML::Response.new do |r|
        # Should be your Twilio Number or a verified Caller ID
        r.Dial :callerId => from do |d|
            d.Client default_client
        end
    end
    response.text
end
