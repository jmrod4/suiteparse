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

#require "suiteparse/version"

module SuiteParse

  require "optparse"

  class Command
     attr_reader :parser, :short_desc

     def initialize(name, short_desc, long_desc, width, indent, &block)
       @name = name
       @short_desc = short_desc
       @long_desc = ((long_desc.nil?)? short_desc : long_desc)
       @block = block
       @parser = OptionParser.new(nil, width, indent) do |parser|
         # XXX parser.program_name doesn't come from the top level parser
         parser.banner = "
usage: #{parser.program_name} #{name} [options] [<args>]

#{@long_desc}

Options:"
       end
     end

     def execute(*args)
       @block.call *args if @block
     end

  end

end # module SuiteParse


class SuiteParser < OptionParser

  def initialize(banner=nil, width=16, indent=' '*3) 
    @debug = true
    @cmds = {}
    @cmds_internal = [:help]
    parser = super(banner, width, indent)
    on_new_command(:help, "show help about commands") do |args|
      argvs = split_argv(args)
      if argvs[:cmd]
	puts @cmds[argvs[:cmd]].parser.help
      else
        puts help
      end    
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

    # only change the default banner if there are at least one command
    # *and* there is no user supplied banner
    if @cmds.empty? and @banner.nil?
      # setup global banner for global help
      @banner = "
usage: #{program_name} [global_options] <command> [options] [<args>]

Gobal options:"
    end

    @cmds[command] = SuiteParse::Command.new(command, short_desc, long_desc, 
          @summary_width, @summary_indent, &block) 
  end

  def on_command(command, *opts, &block)
    # TODO normalize exception
    raise "undefined command #{command}" if not @cmds.has_key? command
    
    @cmds[command].parser.on(*opts, &block)
  end

  def help
    s = super
    # put the end to global help
    s << "\nCommands:\n"
=begin
    # alternative code using the same width as for options
    @cmds.each do |name, cmd| 
      s << @summary_indent
      s << "%*s " % [-@summary_width, name] 
      s << cmd.short_desc
      s << "\n"
    end
=end
    max_len = (@cmds.keys.collect { |name| name.size }).max
    @cmds.keys.sort.each do |name|
      if not @cmds_internal.include? name
        s << @summary_indent
        s << "%*s" % [-max_len-@summary_indent.size, name] 
        s << @cmds[name].short_desc
        s << "\n"
      end
    end


    s << "\n'#{program_name} help <command>' to get additional help." 
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
      @cmds[cmd].parser.permute! argvs[:cmd_argv]
      @cmds[cmd].execute argvs[:cmd_argv]
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


