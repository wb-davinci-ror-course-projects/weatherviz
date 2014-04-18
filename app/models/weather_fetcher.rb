require 'open-uri'
require 'json'

class WeatherFetcher

  # API key for OpenWeatherMap API
  APPKEY = "APPID=#{ENV['OPENWEATHER_APPID']}"

  def self.fetch(location)
    @response = {}

    if location.city_id
      city_url = "http://api.openweathermap.org/data/2.5/weather?id="
      url = URI.escape("#{city_url}#{location.city_id}&#{APPKEY}")
      @response = JSON.parse(open(url).read)
    elsif (location.latitude && location.longitude)
      coordinates_url = "http://api.openweathermap.org/data/2.5/find?"
      coordinates = "lat=#{location.latitude}&lon=#{location.longitude}"
      url = URI.escape("#{coordinates_url}#{coordinates}&#{APPKEY}")
      fetched_data = JSON.parse(open(url).read)
      @response = fetched_data['list'].first
      location.update_attributes(city_id: @response['id'])
    else
      city_and_state_url = "http://api.openweathermap.org/data/2.5/weather?q="
      search = "#{location.city.downcase},#{location.state_code.downcase}"
      url = URI.escape("#{city_and_state_url}#{search}&#{APPKEY}")
      fetched_data = JSON.parse(open(url).read)
      @response = fetched_data['list'].first
    end

    # location.update_attributes(city_id: @response['id']) if location.city_id.nil?

    weather_report = WeatherReport.where(location: location,
      time_received: @response['dt']).first_or_create do |weather_report|

        weather_report.time_received = @response['dt']
        weather_report.sunrise = @response['sys']['sunrise']
        weather_report.sunset = @response['sys']['sunset']
        weather_report.weather = @response['weather'].first['main']
        weather_report.weather_desc = @response['weather'].first['description']
        weather_report.temp = @response['main']['temp']
        weather_report.temp_min = @response['main']['temp_min']
        weather_report.temp_max = @response['main']['temp_max']
        weather_report.pressure = @response['main']['pressure']
        weather_report.humidity = @response['main']['humidity']
        weather_report.wind_speed = @response['wind']['speed']
        weather_report.wind_gust = @response['wind']['gust']
        weather_report.wind_degree = @response['wind']['deg']
        weather_report.clouds = @response['clouds']['all']
        weather_report.rain_3h = @response['rain']['3h'] unless @response['rain'].nil?
        weather_report.snow_3h = @response['snow']['3h'] unless @response['snow'].nil?
      end
    end
end
