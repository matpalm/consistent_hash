#!/usr/bin/env ruby

require 'consistent_hash'
require 'allocation_image'

def allocations_for_hash x
  (0...x.hash_max).step(x.hash_max/1000).collect do |i|
    x.server_for_hashcode i
  end
end

def allocation_differences msg, a0, a1
  same = []
  a0.zip(a1).each do |x,y|
    same << (x==y)
  end
  num_same = same.select{|f|f}.size
  num_changed = same.size - num_same
  puts "#{msg}: num_same=#{num_same} num_changed=#{num_changed}"
  same
end

mod_5 = '01234'.chars.to_a
AllocationImage::generate :values => mod_5 * 20, :possible_values => mod_5, :filename => 'mod_5.png'
mod_4 = '0123'.chars.to_a
AllocationImage::generate :values => mod_4 * 25, :possible_values => mod_5, :filename => 'mod_4.png'
diffs = allocation_differences '5 -> 4 % hash', mod_5 * 20, mod_4 * 25
AllocationImage::difference :diffs => diffs, :filename => 'mod_45_diff.png'


div_5 = ['0']*100 + ['1']*100 + ['2']*100 + ['3']*100 + ['4']*100
AllocationImage::generate :values => div_5, :possible_values => mod_5, :filename => 'div_5.png'
div_4 = ['0']*125 + ['1']*125 + ['2']*125 + ['3']*125
AllocationImage::generate :values => div_4, :possible_values => mod_5, :filename => 'div_4.png'
diffs = allocation_differences '5 -> 4 / hash', div_5, div_4
AllocationImage::difference :diffs => diffs, :filename => 'div_45_diff.png'

[1,20].each do |num_slots|
  x = ConsistentHash.new :seed => 234, :num_slots => num_slots

  servers = %w{server0 server1 server2 server3 server4}
  servers.each { |s| x.add_server s }
  allocs_s01234 = allocations_for_hash x
  AllocationImage::generate :values => allocs_s01234, :possible_values => servers, :filename => "ch_5_#{num_slots}slots.png"
  x.debug_dump_of_slot_allocation

  x.remove_server 'server4' 
  allocs_s0123 = allocations_for_hash x
  AllocationImage::generate :values => allocs_s0123, :possible_values => servers, :filename => "ch_4_#{num_slots}slots.png"
  x.debug_dump_of_slot_allocation

  diffs = allocation_differences 'consistent_hash', allocs_s01234, allocs_s0123
  AllocationImage::difference :diffs => diffs, :filename => "ch_45_diff_#{num_slots}slots.png"
end

x = ConsistentHash.new :seed => 234, :num_slots => 20
servers = %w{server0 server1 server2 server3}
servers.each { |s| x.add_server s }
x.add_server 'server4', 2
allocs_s01234 = allocations_for_hash x
AllocationImage::generate :values => allocs_s01234, :possible_values => servers, :filename => "ch_5_20slots_server4x2.png"
x.debug_dump_of_slot_allocation


