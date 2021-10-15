require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone_number = phone.delete('^0-9')
  length = phone_number.length
  return phone_number if length == 10
  return phone_number[1..10] if length == 11 && phone_number[0] == '1'

  '0000000000'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_date_time(date_time)
  DateTime.strptime(date_time.insert(6, '20'), '%m/%d/%Y %H:%M')
end

def make_report(array)
  hour = get_most_hour(array)
  week_day = get_most_day(array)

  template_report = File.read('report.erb')
  erb_template = ERB.new(template_report)

  report = erb_template.result(binding)
  save_report(report)
end

def get_most_hour(array)
  freq = array.each_with_object(Hash.new(0)) { |v, h| h[v.hour] += 1 }
  array.max_by { |v| freq[v.hour] }.hour
end

def get_most_day(array)
  freq = array.each_with_object(Hash.new(0)) { |v, h| h[v.strftime('%A')] += 1 }
  array.max_by { |v| freq[v.strftime('%A')] }.strftime('%A')
end

def save_report(report_file)

  Dir.mkdir('report') unless Dir.exist?('report')

  filename = 'report/report.html'

  File.open(filename, 'w') { |file| file.puts report_file }
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') { |file| file.puts form_letter }
end

puts 'Event Manager Initialized'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
date_array = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  date_array.push(clean_date_time(row[:regdate]))

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

make_report(date_array)





