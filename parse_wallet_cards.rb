#!/usr/bin/env ruby

# Get nuclear wallet cards file from github, 
# parse it using 'fixed_width', 
# group the data and output it as json

require 'open-uri'
require 'zlib'
require 'fixed_width'
require 'json'

# Description of the nuclear_wallet_cards text file
FixedWidth.define :wallet do |d|
  d.body do |body|
    body.trap { |line| line[0,4] =~ /[^(HEAD|FOOT)]/ }
    body.column :warn, 1
    body.column :A, 3, :parser => :to_i
    body.column :M, 1, :group => :isomeres
    body.spacer 1
    body.column :Z, 3, :parser => :to_i
    body.spacer 1
    body.column :symbol, 2, :parser => :capitalize
    body.spacer 1
    body.column :k, 2
    body.spacer 1
    body.column :Jpi, 14, :group => :isomeres
    body.spacer 1
    body.column :mode, 4, :group => :decays
    body.column :branch, 6, :parser => :to_f, :group => :decays
    body.spacer 2
    body.column :excitation, 6, :parser => :to_f, :group => :isomeres
    body.spacer 1
    body.column :Qvalue, 6, :parser => :to_f, :group => :decays
    body.column :S, 1
    body.spacer 6
    body.column :halflife_string, 18, :group => :isomeres
    body.column :abundance, 16
    body.column :massex, 8, :parser => :to_f, :group => :isomeres
    body.spacer 1
    body.column :massexd, 7, :parser => :to_f, :group => :isomeres
    body.spacer 1
    body.column :S2, 1 
    body.spacer 2 
    body.column :reference, 6
    body.spacer 1 
    body.column :halflife, 8, :parser => :to_f, :group => :isomeres
  end
end


def collect_values(hashes, what)
    {}.tap{ |r| hashes.each{ |h| h.each{ |k,v|
        if k == what
            (r[k]||=[]) << v
        else
            r[k] = v
        end
    } } }
end


# Get raw data
file = Zlib::GzipReader.new( URI.parse('https://github.com/jhykes/nuclide-data/raw/master/nuclear-wallet-cards.txt.gz').open({ssl_verify_mode: 0}) )
data = FixedWidth.parse(file, :wallet)[:body]

# Remove unecessary data
filtered_data = data.each do |i|
    i[:isomeres][:decays] = i[:decays].dup
    i.delete(:decays)
    i.delete(:S)
    i.delete(:S2)
    i.delete(:reference)
    i.delete(:warn)
    i.delete(:k)
end

# Combine isomeres of entries with same Z and A
joined_data = filtered_data.group_by{|i| [i[:Z], i[:A]]}.collect{|_,data| collect_values(data,:isomeres) }

# Combine Decay modes of the same isomere
joined_data = joined_data.collect do |i|
    i[:isomeres] = i[:isomeres].group_by{|iso| iso[:excitation]}.collect{|_,data| collect_values(data,:decays) }
    i
end

puts JSON.pretty_generate(joined_data)
