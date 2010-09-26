require 'set'

class ConsistentHash

  attr_reader :server_slots, :uhash_max, :servers

  def initialize opts={}
    @num_slots = opts[:num_slots] || 20
    @uhash_max = opts[:uhash_max] || 90107
    @seed_length = opts[:seed_length] || 20
    srand(opts[:seed]) if opts.has_key?(:seed)
    @uhashs = []
    @servers = Set.new
    @server_slots = [] # [ [12,'server1'], [24,'server2'], ... ]
  end

  def add_server server, num_slots_multiplier = 1
    return if @servers.include? server
    num_slots = @num_slots * num_slots_multiplier
    ensure_number_uhash_functions_at_least num_slots
    @servers << server
    @uhashs.slice(0,num_slots).each do |uhash|
      slot = uhash.hash_of server
      @server_slots << [slot, server]
    end
    @server_slots = @server_slots.sort_by { |slot| slot.first }
  end

  def remove_server server
    return unless @servers.include? server
    @servers.delete server
    @server_slots.reject! { |slot,svr| svr == server }
  end

  def ensure_number_uhash_functions_at_least n
    while @uhashs.size < n
      @uhashs << Uhash.new(@uhash_max, @seed_length)
    end
  end

  def server_for_hashcode hc
    @server_slots.each do |slot,svr|
      return svr if hc < slot
    end
    return @server_slots.first.last # wrap around case, return first server
  end

end

class Uhash

  def initialize uhash_max = 2305843009213693951, seed_length=20
    @uhash_max = uhash_max
    @seed = seed_length.times.collect { rand @uhash_max }
  end

  def hash_of str
    sum = seed_idx = 0
    str.bytes.each do |b|
      sum += b * @seed[seed_idx]
      seed_idx += 1
      seed_idx %= @seed.length
    end
    sum % @uhash_max
  end

end
