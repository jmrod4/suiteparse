# 
# suiteparser.rb - allow OptionParser class to process command suites
#
# SuiteParser is a derived class from Ruby library OptionParser to allow 
# processing of command line suites, as a lightweight alternative to thor, 
# commander or GLI 
#
# Author:: Juanma Rodriguez
#
# Release:: February 2016
#
# Any sugestions, comments or bug reports welcome.
#
# ### HOW TO USE
#
# **Please see the test example at the end of this file!**
#
# Pros:
#  * same calling syntax and operation, just use SuiteParser instead
#    of Option Parser
#  * no need to add other gems or, even worse, that gems' dependences
#
# Cons:
#  * you tell me :)
#
# Known problems:
#  * not managed (i.e. breaks) if user calls directly: order!, order
#
# ### LICENSING
#
# Copyright 2016 Juanma Rodriguez
#
# You can use and distribute it under the terms of the LGPL Version 3
# This is free software and is offered without any warranty.
#
require 'optparse'

class SuiteParser < OptionParser

  def initialize
    @cmds = {}
    @blocks = {}
    super
  end

  def on_command(command, *opts, &block)
    if @cmds.size < 1
      self.banner = "Usage: #{program_name} [options] <command> [options] [<args>]"
    end

    if not @cmds.has_key?(command)
      newparser = OptionParser.new
      newparser.banner = "Usage: #{self.program_name} #{command} [options]"
      if opts.size > 1 && opts[0].nil?
        newparser.banner = "\n#{command}: #{opts[1]}\n" + newparser.banner
      end
      @cmds[command] = newparser
    end

    if opts.size > 0 
      if opts[0].nil?
        @blocks[command] = block 
      else
        @cmds[command].on(*opts, &block)
      end
    end
  end

  def help
    s = super
    @cmds.each { |cmd, parser| s += parser.help }
    s
  end

  def split_argv(argv)
    cmd_pos = argv.index { |arg| @cmds.keys.include? arg.to_sym }
    
    return {global_argv: argv} if cmd_pos.nil?
    res = {} 
    res[:cmd] = argv[cmd_pos].to_sym
    res[:global_argv] = argv.first(cmd_pos)
    res[:cmd_argv] = argv[cmd_pos+1..-1]
    res
  end

  def parse!(argv = default_argv)
    a = split_argv(argv) 
    super a[:global_argv]
    cmd = a[:cmd]
    if cmd
      @blocks[cmd].call if @blocks[cmd]
      @cmds[cmd].parse! a[:cmd_argv]
    end
    argv.replace(a[:global_argv] + (a[:cmd_argv] || []))
  end
end



if __FILE__ == $0

  options = {}

  p "ARGV", ARGV
  
  parser = SuiteParser.new do |parser|

    parser.on("-d", "--debug") do
      options[:debug] = true
      parser.warn "Debug activated!"
    end

    parser.on_command(:add, nil,
                      "add something!") do 
      options[:command] = :add
      options[:add] = {}
    end  
    
    parser.on_command(:add, "-a", "--all") do
      options[:add][:all] = true
    end

    parser.on_command(:list, nil,
                      "list something!") do 
      options[:command] = :list
      options[:list] = {}
    end  
    
    parser.on_command(:list, "-s", "--sort",
                      "order everything!") do
      options[:list][:sort] = true
    end
  end

  parser.parse!

  p "ARGV", ARGV
  p "options", options
end

