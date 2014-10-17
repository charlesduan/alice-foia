#!/usr/bin/env ruby

require 'csv'

def display_row(row)
  puts "Symbol:    #{row[0]}"
  puts "Name:      #{row[1]}"
  puts "Industry:  #{row[6]}\t#{row[7]}"
  open("| pbcopy", 'w') do |f|
    f.puts "#{row[6]}\t#{row[7]}"
  end
end

data = CSV.read("icb.csv")

symbols = {}
data.each do |row| symbols[row[0].downcase] = row end

puts "Ready"

STDIN.each do |line|
  line = line.chomp.downcase
  row = symbols[line]
  if row
    display_row(row)
  else
    count = 0
    data.each do |row|
      if row[1].downcase.include?(line)
        display_row(row)
        count += 1
        break if count > 10
      end
    end
    puts "Not found" if count == 0
  end
end


