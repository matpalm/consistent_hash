#!/usr/bin/env ruby
require 'set'

class ConsistentHash

  UHASH_MAX = 90107
  #M = 2305843009213693951

  R = 20 # length of hash seed; average length in bytes of what you're hashing
  DFT_NUM_SLOTS_PER_SERVER = 20

  attr_reader :server_slots

  def initialize opts={}
    @num_slots = opts[:num_slots] || DFT_NUM_SLOTS_PER_SERVER
    srand(opts[:seed]) if opts.has_key?(:seed)
    @uhash_seeds = @num_slots.times.collect { uhash_seed }
    @servers = Set.new
    @server_slots = [] # [ [12,'server1'], [24,'server2'], ... ]
  end

  def add_server server
    return if @servers.include? server
    @servers << server
    slots_for_server = @uhash_seeds.map { |seed| uhash_of(server, seed) }
    @server_slots += slots_for_server.map { |slot| [slot,server] }
    @server_slots = @server_slots.sort_by { |slot| slot.first }
  end

  def remove_server server
    return unless @servers.include? server
    @servers.delete server
    @server_slots.reject! { |slot,svr| svr == server }
  end

  def hash_max
    UHASH_MAX
  end

  def server_for_hashcode hc
    idx = 0
    while true do
      slot, svr = @server_slots[idx]
      return svr if hc < slot || idx == @server_slots.size-1
      idx += 1
    end
  end

  def debug_dump_of_slot_allocation
    expected_proportion_per_server = 1.0 / @servers.size
    last_slot = 0
    proportion_per_server = Hash.new(0)
    @server_slots.each do |slot, server|
      slot_size = slot - last_slot
      proportion_per_server[server] += slot_size
      last_slot = slot
    end
    final_slot, final_server = @server_slots.last
    proportion_per_server[final_server] += UHASH_MAX - final_slot
    error = 0.0
    proportion_per_server.each do |server,weight|
      proportion = weight.to_f / UHASH_MAX
      error += (proportion-expected_proportion_per_server).abs
      printf "%s => %0.5f ", server, proportion
    end
    printf " avg err %0.3f\n", error/@servers.size
  end

  private

  def uhash_seed
    a = R.times.collect { rand UHASH_MAX }
  end

  def uhash_of str, seed
    sum = seed_idx = 0
    str.bytes.each do |b|
      sum += b * seed[seed_idx]
      seed_idx += 1
      seed_idx %= seed.length
    end
    sum % UHASH_MAX
  end

end

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
end

colours = ['a'=>[1,0,0], 'b'=>[1,1,0], 'c'=>[0,1,0], 'd'=>[0,1,1], 'e'=>[0,0,1]]

mod_5 = '01234'.chars.to_a
mod_4 = '0123'.chars.to_a
allocation_differences '5 -> 4 % hash', mod_5 * 200, mod_4 * 250

div_5 = ['0']*200 + ['1']*200 + ['2']*200 + ['3']*200 + ['4']*200
div_4 = ['0']*250 + ['1']*250 + ['2']*250 + ['3']*250
allocation_differences '5 -> 4 / hash', div_5, div_4

x = ConsistentHash.new :seed => 234
%w{server0 server1 server2 server3 server4}.each { |s| x.add_server s }
allocs_s01234 = allocations_for_hash x
x.debug_dump_of_slot_allocation
%w{server4}.each { |s| x.remove_server s }
allocs_s0123 = allocations_for_hash x
x.debug_dump_of_slot_allocation
allocation_differences 'consistent_hash', allocs_s01234, allocs_s0123




