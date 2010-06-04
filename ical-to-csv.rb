require 'rubygems'
require 'icalendar'
require 'csv'

# Read in the ical file
cal_file = File.open("may-2010/may-tasks.ics")

# Parser returns an array of calendars because a single file
# can have multiple calendars.
cals = Icalendar.parse(cal_file)
cal = cals.first

#Write a CSV File
CSV.open('may-2010/may-tasks.csv', 'w') do |csv|
  cal.events.each{|event|
    # the returned number is a rational and is the number of days difference
    hours = ((event.end-event.start)*24).to_f
    csv << [event.start.to_s, event.end.to_s, hours.to_s, event.summary]
  }
end