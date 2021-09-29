require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  number = phone_number.to_s.tr('^0-9', '')
  if number.length > 11 || number.length < 10
    'bad number'
  elsif number.length == 11 && number[0] == '1'
    number.delete_prefix('1')
  else
    number.rjust(10, '0')[0..9]
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

days_arr = []
hours_arr = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  registration_date = row[:regdate].split
  registration_weekday = Date.strptime(registration_date[0], '%D').wday
  registration_hour = Time.strptime(registration_date[1], '%k:%M').hour
  legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  days_arr << registration_weekday
  hours_arr << registration_hour
end
 
days_arr.map! do |d, n|
  case d
  when 0
    'Sunday'
  when 1
    'Monday'
  when 2
    'Tuesday'
  when 3
    'Wednesday'
  when 4
    'Thursday'
  when 5
    'Friday'
  when 6
    'Saturday'
  end
end

days_sorted = days_arr.tally.sort_by { |day, frequency| frequency }.reverse!
hours_sorted = hours_arr.tally.sort_by { |hour, frequency| frequency }.reverse!

puts "The most common day that people registered on was #{days_sorted[0][0]}"
puts "The most common hour that people registered during was #{hours_sorted[0][0]}:00"