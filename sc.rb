require 'Colorize'

$times = {main: []} # data hash worked on and shared across all methods
$current_set = :main # default
$time_at_start = ""
$help_file =
" \nINSTRUCTIONS:\n"\
"After starting a counter, press <enter> to increment.\n"\
"Commands: <enter> to start counter (h)elp (q)uit program"
$inner_help_file =
" \nINSTRUCTIONS:\n"\
"Press <enter> to increment, or type a command.\n"\
"Commands: (h)elp (q)uit counter (p)ause"

def save_new_time
  $times[$current_set] << Time.now
end

# seconds to minutes-and-seconds, returns strings of form "43s", "4m32s"
def s_to_ms(secs)
  return "#{secs.round(1).to_s}s" if secs < 60
  mins = (secs / 60).floor # rounds down
  secs = secs - (mins * 60)
  return "#{mins}m#{secs.round(0)}s"
end

def generate_and_display_stats
  puts "+++++++++++++"
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
  puts "Avg/min, last 3m: #{three_min_avg.round(1)}.".cyan +
    " Avg/min, total: #{total_avg.round(1)}" unless
    Time.now - $time_at_start < 180
end

def pause_counter
  input = "paused"
  pause_start = Time.now
  until input == ''
    puts "+++++++++++++"
    print "Paused. <enter> again to continue. "
    input = gets.chomp
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
  $time_at_start = Time.now
  puts " \nStarting counter '#{$current_set.to_s}'. Press <enter> to increment."
  while counter_running
    print $current_set.to_s + "> "
    input = gets.chomp # script pauses here
    case input
    when 'q', 'Q', 'quit', "Quit", "QUIT"
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
      generate_and_display_stats
    when ""
      then save_new_time
      generate_and_display_stats
    else
      puts "Not understood."
    end
  end
end

system("cls") || system("clear")
puts "Welcome to Smart Counter!"
puts "Press <enter> to begin a new counter.\n"

# enclosing loop, to start and stop review
command = ""
until ['q', 'Q', 'quit', "Quit", "QUIT"].include?(command)
  print "=> "
  command = gets.chomp
  case command
  when 'h', 'help', '?', 'man', 'instructions'
    then puts $help_file
  when 'q', 'Q', 'quit', "Quit", "QUIT"
    then puts "Goodbye!"
  when ''
    then counter(true)
  else
    puts "Not understood."
  end
end
