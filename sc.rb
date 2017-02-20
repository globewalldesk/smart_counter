require 'Colorize'
require 'yaml'

$times = {} # data hash worked on and shared across all methods
$current_set = :main # default
$time_at_start = ""
$help_file =
" \nINSTRUCTIONS:\n"\
"After starting a counter, press <Enter> to increment.\n"\
"Commands: <Enter> to start counter (h)elp (q)uit program\n"\
"(s)witch counter"
$inner_help_file =
" \nINSTRUCTIONS:\n"\
"Press <Enter> to increment, or type a command.\n"\
"Commands: (h)elp (q)uit counter (p)ause"

def save_new_time
  $times[$current_set] ||= []
  now = Time.now
  # the following makes sure the item saved starts at the current second; no millisecs
  # allows lookup with .include? to work in get_minute_progress
  $times[$current_set] << Time.new(now.year, now.month, now.day, now.hour, now.min, now.sec)
  # save to YAML file here (not done yet)
end

# seconds to minutes-and-seconds, returns strings of form "43s", "4m32s"
def s_to_ms(secs)
  return "#{secs.round(1).to_s}s" if secs < 60
  mins = (secs / 60).floor # rounds down
  secs = secs - (mins * 60)
  return "#{mins}m#{secs.round(0)}s"
end

# This generates one 60-char long bar representing the previous one minute,
# showing with X the second during which you incremented the counter.
def get_minute_progress
  now = Time.now
  # get beginning of minutes
  curr = Time.new(now.year, now.month, now.day, now.hour, now.min)
  prev = Time.new(now.year, now.month, now.day, now.hour, now.min) - 60
  string_last_min = ""
  string_this_min = ""
  # actually calculate content of string: go through all seconds in sequence;
  # check if $times($current_set) contains the second in question; if so, mark
  # a '#'; otherwise, mark a '.'.
  60.times do
    string_last_min += ($times[$current_set].include?(prev) ? "#" : ".")
    prev += 1
  end
  60.times do
    if now >= curr
      string_this_min += ($times[$current_set].include?(curr) ? "#" : ".")
    else # color future seconds green
      string_this_min += ".".green
    end
    curr += 1
  end
  return string_last_min, string_this_min
end

def generate_and_display_stats(*yo)
  puts "+++++++++++++" unless yo
  return unless $times[$current_set] # catches instance when user quits before incrementing
  elapsed = $times[$current_set][-2] ? $times[$current_set][-1] -
    $times[$current_set][-2] : $times[$current_set][-1] - $time_at_start
  elapsed_since_start = $times[$current_set][-1] - $time_at_start
  print "Elapsed: #{s_to_ms(elapsed)}.".red + " Since "\
    "start: #{s_to_ms(elapsed_since_start)}.".green + " \n"
  total_last_one_min = $times[$current_set].count {|time| Time.now - time < 60 }
  total_total = $times[$current_set].length
  print "1m counted: #{total_last_one_min}.".yellow +
    " Total counted: #{total_total}.".magenta + " \n"
  total_last_three_mins = $times[$current_set].count {|time| Time.now - time < 180 }
  three_min_avg = total_last_three_mins.to_f / 3
  total_avg = $times[$current_set].length / ((Time.now - $time_at_start) / 60)
  last_minute, this_minute = get_minute_progress
  puts "Avg/min, last 3m: #{three_min_avg.round(1)}.".cyan +
    " Avg/min, total: #{total_avg.round(1)}" unless
    Time.now - $time_at_start < 180
  puts last_minute, this_minute, "\n"
end

def pause_counter
  input = "paused"
  pause_start = Time.now
  until input == ''
    puts "\n"
    generate_and_display_stats("yo")
    puts "**** PAUSED ****"
    print "Press <Enter> again to continue. "
    input = gets.chomp
    return unless $times[$current_set] # catches case where user pauses before incrementing
    # unpausing effectively moves the start time & all times in $times forward
    # by the elapsed amount
    if input == ''
      elapsed = Time.now - pause_start
      $time_at_start += elapsed
      $times[$current_set].map! {|time| time += elapsed}
    end
  end
end

def delete_last
  $times[$current_set].pop
  puts "+++++++++++++"
  puts "Deleted last."
end

# update both times and stats endlessly
def counter(counter_running)
  # first load existing data from yaml file; might need to prompt the user, or
  # to accept a param on the command line here, to clear old data. (not done yet)
  $time_at_start = Time.now
  puts " \nStarting counter '#{$current_set.to_s}'. Press <Enter> to increment."
  while counter_running
    print $current_set.to_s + "> "
    input = gets.chomp
    case input
    when 'q', 'Q', 'quit', "Quit", "QUIT", "exit", "Exit", "EXIT"
      then counter_running = false
      puts "Quitting '#{$current_set}'."
      break
    when 'h', 'help', '?', 'man', 'instructions'
      then puts $inner_help_file
    when 'p'
      then pause_counter
      generate_and_display_stats
    when 'd'
      then delete_last
      generate_and_display_stats unless $times[$current_set].length == 0
    when ""
      then save_new_time
      generate_and_display_stats
    else
      puts "Not understood."
    end
  end
end

def switch_counter(*argument)
  input = ""
  loop do
    if argument[0]
      input = argument[0]
      argument = nil
    else
      print "Enter name of counter: "
      input = gets.chomp
    end
    if input.split(//).all? { |let| [*('A'..'Z'), *('a'..'z')].join.include?(let) }
      $current_set = input.to_sym
      puts "Switched to #{$current_set}."
      puts "To start the #{$current_set} counter, press <Enter>."
      break
    else
      puts "Only letters, please."
    end
  end
end
 
system("cls") || system("clear")
puts "=" * 60
puts "Welcome to Smart Counter!"
puts "Press <Enter> to begin a new counter.\n"

def parse(input)
  if input == ""
    return ""
  elsif input.split(" ")[0] == input
    return input
  else
    input = input.split(" ")
    return input[0], input[1]
  end
end

# enclosing loop, to start and stop review
command = ""
until ['q', 'Q', 'quit', 'Quit', 'QUIT', 'exit', 'Exit', 'EXIT'].include?(command)
  print "=> "
  command = gets.chomp
  command, argument = parse(command)
  case command
  when 'h', 'help', '?', 'man', 'instructions'
    then puts $help_file
  when 'q', 'Q', 'quit', 'Quit', 'QUIT', 'exit', 'Exit', 'EXIT'
    then puts "Goodbye!"
  when 's'
    then switch_counter(argument)
  when ''
    then counter(true)
  else
    puts "Not understood."
  end
end
