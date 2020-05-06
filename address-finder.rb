require 'csv'
require 'faraday'
require 'json'
require 'byebug'
require 'dotenv/load'


input_file = './test.csv'
input_headers = [:facility, :county, :deaths]

output_file = "./updated_test.csv"
output_headers = [:facility, :deaths, :name, :formatted_address, :county, :lat, :lng, :place_id, :results]


# GET DATA FROM CSV FILE
def import_data(input_file, input_headers)
  data = []
  
  CSV.foreach(input_file, {col_sep: ', ', quote_char: '"', headers: true}) do |row|
    newObj = {}
    i = 0

    for key in input_headers do
      newObj[key] = row[i]
      i += 1
    end

    data << newObj
  end
  
  data
end

# ADD DATA FROM GOOGLE
def add_place_data(data)
  return data.map do |item|
    url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?'
    parameters = {
      input: item[:facility],
      inputtype: 'textquery',
      fields: 'formatted_address,geometry,name,place_id',
      locationbias: 'circle:2000@40.6976701,-74.2598761',
      key: ENV['GOOGLE_API_KEY']
    }
    resp = Faraday.get(url, parameters, {'Accept': 'application/json'})
    json = JSON.parse(resp.body)

    item[:formatted_address] = json["candidates"].first["formatted_address"]
    item[:lat] = json["candidates"].first["geometry"]["location"]["lat"]
    item[:lng] = json["candidates"].first["geometry"]["location"]["lng"]
    item[:name] = json["candidates"].first["name"]
    item[:place_id] = json["candidates"].first["place_id"]
    item[:results] = json["candidates"].length

    puts item
    item
  end
end

# WRITE TO CSV
def write_to_csv(output_file, output_headers, data)
  CSV.open(output_file, 'w', write_headers: true, headers: output_headers) do |writer|
    data.each do |record|
      record_array = []
      output_headers.each do |field|
        record_array << record[field]
      end
      writer << record_array
    end
  end
end


write_to_csv(output_file, output_headers, add_place_data(import_data(input_file, input_headers)))





# TESTING FARADAY IN IRB
# require 'faraday'
# require 'json'
# url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
# parameters = {
#   input: 'NYS Veterans Home in NYC',
#   inputtype: 'textquery',
#   fields: 'formatted_address,geometry,name,place_id',
#   locationbias: 'circle:2000@40.6976701,-74.2598761',
#   key: ENV['GOOGLE_API_KEY']
# }
# resp = Faraday.get(url, parameters, {'Accept': 'application/json'})
# json = JSON.parse(resp.body)  

# item[:formatted_address] = json["candidates"].first["formatted_address"]
# item[:lat] = json["candidates"].first["geometry"]["location"]["lat"]
# item[:lng] = json["candidates"].first["geometry"]["location"]["lng"]
# item[:name] = json["candidates"].first["name"]
# item[:place_id] = json["candidates"].first["place_id"]
# item[:results] = json["candidates"].length

# pp json

