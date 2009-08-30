#!/usr/bin/ruby
#
# Takes a .ics file as parameter, adds it to Google Calendar
#
# Change USERNAME and PASSWORD to your username and password, respectively,
# set DEFAULT_CAL to define the calendar selected by default (you'll still
# get the option to choose one).
#
# (C) 2009 David Verhasselt (david@crowdway.com)
#
# Licensed under MIT License, see included file LICENSE

USERNAME = "user"
PASSWORD = "password"
DEFAULT_CAL = ""

require 'gtk2'
require 'rubygems'
require 'googlecalendar'

# Make "calendars" accessible
class Googlecalendar::GData
	attr_reader :calendars
end

if ARGV.length < 1
	puts "Need at least 1 .ics file"
	exit
end

# Parse the iCal file
iCal = parse(IO.read(ARGV[0]));

if iCal.events.length < 1
	puts ".ics file doesn't contain any events"
	exit
end

g = Googlecalendar::GData.new;
g.login(USERNAME, PASSWORD);
g.get_calendars();

cals = g.calendars.map { |item| item.title }

# Create GUI
window = Gtk::Window.new
window.title = "Add iCal"
window.border_width = 5 

vBoxMain = Gtk::VBox.new(false, 5)
window.add(vBoxMain)

descriptionTable = Gtk::Table.new(5, 2, false)
descriptionTable.set_row_spacings(5)
descriptionTable.set_row_spacing(0, 10)
vBoxMain.pack_start(descriptionTable)

label = Gtk::Label.new;
label.set_markup("<big>Add iCal to Google Calendar</big>")
descriptionTable.attach(label, 0, 2, 0, 1)

if iCal.events.length > 1
	label = Gtk::Label.new("Events found:")
	descriptionTable.attach(label, 0, 1, 1, 2)

	label = Gtk::Label.new(iCal.events.length.to_s)
	descriptionTable.attach(label, 1, 2, 1, 2)
end

label = Gtk::Label.new("Event:")
descriptionTable.attach(label, 0, 1, 2, 3)

label = Gtk::Label.new(iCal.events[0].summary)
descriptionTable.attach(label, 1, 2, 2, 3)

label = Gtk::Label.new("Date:")
descriptionTable.attach(label, 0, 1, 3, 4)

label = Gtk::Label.new(iCal.events[0].start_date.to_s)
descriptionTable.attach(label, 1, 2, 3, 4)


separator = Gtk::HSeparator.new()
descriptionTable.attach(separator, 0, 2, 4, 5)

controlBox = Gtk::HBox.new(false, 0)
vBoxMain.pack_end(controlBox, true, true, 0)

calSelector = Gtk::ComboBox.new(true)
cals.each { |title| calSelector.append_text(title) }
calSelector.active = cals.index(DEFAULT_CAL) || 0
controlBox.pack_start(calSelector, true, true, 0)

window.signal_connect("delete_event") do
	Gtk.main_quit
	false
end

buttonAdd = Gtk::Button.new("Add event")
buttonAdd.signal_connect("clicked") do
	iCal.events.each do |event|
		eventHash = {}
		eventHash[:title] = event.summary
		eventHash[:content] = event.description
		eventHash[:where] = event.location
		eventHash[:startTime] = event.start_date
		eventHash[:endTime] = event.end_date
		eventHash[:author] = "iCal2GCal"
		eventHash[:email] = "iCal2GCal"

		g.new_event(eventHash, calSelector.active_text)

	end

	Gtk.main_quit
	false
end
controlBox.pack_start(buttonAdd, true, true, 0)
window.show_all
Gtk.main
