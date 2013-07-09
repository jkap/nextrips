require 'nokogiri'
require 'open-uri'
require 'sinatra'
require 'sinatra/json'
require 'json'
require 'rdiscount'

set :json_encoder, JSON

get '/' do
  markdown :index
end

get '/nextrip/:stop' do
  url = "http://www.metrotransit.org/Mobile/NexTripGps.aspx?stopnumber=#{params[:stop]}"

  page = Nokogiri::HTML(open(url))

  rows = page.css('.nextripDepartures .data')

  departures = {nextrips:[]}

  departures[:stop] = page.css('#ctl00_mainContent_NexTripControl1_NexTripResults1_lblLocation').text
  departures[:web] = url

  rows.each do |row|
    departure = {}
    route = row.css('.col1').text
    if ((params[:route] && route.match(params[:route])) || !params[:route])
      departure["route"] = route
      departure["desc"] = row.css('.col2').text
      departure["time"] = row.css('.col3').text
      classes = row.css('.col3')[0]["class"].split
      departure["realTime"] = !(classes.include? "red")
      departures[:nextrips] << departure
    end
  end
  json departures
end