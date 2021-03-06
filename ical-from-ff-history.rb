# this is currently based on the rvm 1.9.1%timesheet

require 'rubygems'
require 'sqlite3'
require 'date'
require 'icalendar'

db = SQLite3::Database.new( "places.sqlite" )

year = 2010
month = 5
start_time = Time.local(year, month).to_i * 1000000
end_time = Time.local(year, month + 1).to_i * 1000000

# ["id", "from_visit", "place_id", "visit_date", "visit_type", "session", "id", "url", "title", 
#  "rev_host", "visit_count", "hidden", "typed", "favicon_id", "frecency", "last_visit_date"]
query = "select * from moz_historyvisits, moz_places " +
        "where moz_historyvisits.place_id=moz_places.id " + 
        "and moz_historyvisits.visit_date>#{start_time} " + 
        "and moz_historyvisits.visit_date<#{end_time}"
length = 0
cal = Icalendar::Calendar.new

class VisitEvent
  attr_accessor :visit_date, :from_visit, :url, :title, :session
  
  def initialize(row)
    @from_visit = row[1].to_i
    @visit_date = row[3].to_i
    @session = row[5].to_i
    @url = row[7]
    @title = row[8]
  end
  
  def visit_time
    Time.at(self.visit_date / 1000000)
  end
  
end

class VisitEventTrail
  attr_accessor :events
  
  def initialize()
    @events = []
  end  
  
  def add(event)
    events.push event
  end
  
  def dtstart
    events.first.visit_time.to_datetime
  end
  
  def dtend
    first_time = events.first.visit_time
    # use a 8 minute minimun event size
    end_time = first_time + 8*60
    if events.last.visit_time > end_time
      end_time = events.last.visit_time
    end
    end_time.to_datetime
  end
  
  def description
    events.collect{|event|
      event.visit_time.strftime("%I:%M:%S") + ": " + event.title
    }.join("\n")    
  end
end

visit_events = []
visit_trails = []

db.execute(query) {|row|
  last_event = visit_events.last
  event = VisitEvent.new(row)
  visit_events.push(event)

  puts event.visit_time
    
  # look for overlaping events
  if (last_event and (last_event.visit_time + 180) > event.visit_time)
    visit_trails.last.add event
    next
  end

  visit_trail = VisitEventTrail.new
  visit_trail.add event
  visit_trails.push visit_trail
}

visit_trails.each {|trail|
  cal.event {
    dtstart trail.dtstart
    dtend trail.dtend
    description trail.description
    summary trail.events.first.title
    url trail.events.first.url    
  }  
}

puts "length: #{visit_trails.length}"
File.open("history.ics", 'w') {|f|
  f.write cal.to_ical
}