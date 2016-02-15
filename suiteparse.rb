# 
# suiteparser.rb - allow OptionParser class to process command suites
#
# SuiteParser is a derived class from Ruby library OptionParser to allow 
# processing of command line suites, as a lightweight alternative to thor, 
# commander or GLI 
#
# Author:: Juanma Rodriguez
#
# Release:: February 2016 - Alpha
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

  class Command
     attr_reader :parser

     def initialize(name, short_desc, long_desc=nil, &block)
       @name = name
       @short_desc = short_desc
       @long_desc = ((long_desc.nil?)? short_desc : long_desc)
       @block = block
       parser = OptionParser.new
       # XXX parser.program_name doesn't come from the top level parser
       parser.banner = "#{short_desc}

Usage: #{parser.program_name} #{name} [options]"
       @parser = parser
     end

     def execute
       @block.call if @block
     end
  end

  def initialize
    @debug = true
    @cmds = {}
    parser = super
    on_new_command(:help, "show help about commands") do
      puts help
      exit 1
    end
    parser
  end

  def debug(msg)
    if @debug
      puts "#{program_name}: debug: #{msg}"
    end
  end

  def on_new_command(command, short_desc, long_desc=nil, &block)
    # TODO normalize exception
    raise "command <#{command}> already defined" if @cmds.has_key? command

    if @cmds.empty?
      # setup global banner
      banner = "Usage: #{program_name} [global_options] <command> [options] [<args>]"
    end

    @cmds[command] = Command.new(command, short_desc, long_desc, &block) 
  end

  def on_command(command, *opts, &block)
    # TODO normalize exception
    raise "undefined command #{command}" if not @cmds.has_key? command
    
    @cmds[command].parser.on(*opts, &block)
  end

  def help
    s = super
    @cmds.each { |name, cmd| s << cmd.parser.help }
    s
  end

  # return a hash of: global_argv, command, cmd_argv
  def split_argv(argv)
    cmd_pos = argv.index { |arg| @cmds.keys.include? arg.to_sym }
    
    return {global_argv: argv, cmd: nil, cmd_argv: []}   if cmd_pos.nil? 

    res = {} 
    res[:cmd] = argv[cmd_pos].to_sym 
    res[:global_argv] = argv.first(cmd_pos)
    res[:cmd_argv] = argv[cmd_pos+1..-1]
    res
  end

  def permute!(full_argv = default_argv)
    argvs = split_argv(full_argv) 
    super argvs[:global_argv]
    cmd = argvs[:cmd]
    if cmd
      @cmds[cmd].execute
      @cmds[cmd].parser.permute! argvs[:cmd_argv]
    end
    
    #TODO normalize exceptions
    if argvs[:global_argv].size > 0
      raise "unrecognized command #{argvs[:global_argv]}"
    end

    full_argv.replace(argvs[:cmd_argv])
  end
end



if __FILE__ == $0

  options = {}

  puts "ARGV = " + ARGV.inspect
  
  parser = SuiteParser.new do |parser|

    parser.on("-d", "--debug") do
      options[:debug] = true
      parser.warn "Debug activated!"
    end

    parser.on_new_command(:add, 
        "add something!") do 
      options[:command] = :add
      options[:add] = {}
    end  
    
    parser.on_command(:add, "-a", "--all") do
      options[:add][:all] = true
    end

    parser.on_new_command(:list,
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

  parser.debug "ARGV = " + ARGV.inspect
  parser.debug "options = " + options.inspect
end

