require 'open-uri'
require 'sinatra/json'
require 'json'

set :json_encoder, JSON


def departures_for_stop(stop, route = nil, real_time = nil)
  url = "http://www.metrotransit.org/Mobile/NexTripGps.aspx?stopnumber=#{stop}"

  page = Nokogiri::HTML(open(url))

  rows = page.css('.nextripDepartures .data')

  departures = {nextrips:[]}

  departures[:stop] = page.css('#ctl00_mainContent_NexTripResultsDisplay_lblLocation').text
  departures[:web] = url

  rows.each do |row|
    departure = {}
    route = row.css('.col1').text
    if ((route && route.match(route)) || !route)
      departure[:route] = route
      departure[:desc] = row.css('.col2').text
      departure[:time] = row.css('.col3').text
      classes = row.css('.col3')[0]["class"].split
      departure[:realTime] = !(classes.include? "red")
      departures[:nextrips] << departure if (real_time && departure[:realTime]) || !real_time
    end
  end
  departures
end

get '/' do
  markdown :index
end

get '/nextrip/:stop' do
  real_time = params[:realTime].nil? ? false : params[:realTime] == "true"
  departures = departures_for_stop(params[:stop], params[:route], real_time)
  
  json departures
end

get '/commute' do
  stops = [{stop: 51839, route: 535}, {stop: 1854}, {stop: 53543}]

  @nextrips = []

  stops.each do |stop|
    departures = departures_for_stop(stop[:stop], stop[:route], stop[:real_time])
    @nextrips << departures
  end

  haml :commute
end
