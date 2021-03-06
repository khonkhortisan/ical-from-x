#!/usr/bin/env ruby

require 'rubygems'
require 'icalendar'
require 'csv'

dir = "/Users/scytacki/Google Drive/CCProjects/Timesheets/nov-2015"

# Read in the ical file
cal_file = File.open("#{dir}/tasks.ics")

# Parser returns an array of calendars because a single file
# can have multiple calendars.
cals = Icalendar.parse(cal_file)
cal = cals.first

#Write a CSV File
out_file = "#{dir}/tasks.csv"
CSV.open(out_file, 'w') do |csv|
  csv << ['start', 'end', 'hours', 'task', 'type', 'project']
  cal.events.each{|event|
    # the returned number is a rational and is the number of days difference
    hours = ((event.end-event.start)*24).to_f
    csv << [event.start.to_s, event.end.to_s, hours.to_s, event.summary]
  }
end
puts "Wrote: #{out_file}"