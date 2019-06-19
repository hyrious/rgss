# coding: utf-8
#==============================================================================
# PluginManager.rb
#==============================================================================
# @plugindesc This script adds "Plugin Manager" to RPG Maker VX Ace.
# @author hyrious
# 
# @param PATH
# @desc Folders where *.rb are treated as "plugins". Separate them with ';'.
# Example: C:\RMSFX;D:\Inbox
# 
# @param Config File
# @default Plugins.ini
# @desc Plugin configs are stored here. Just plain text (ini).
# You must set this param programmatically, put codes below into your editor:
# PluginManager.parameters('PluginManager')['Config File'] = './Plugins.ini'
# 
# @help This plugin does not provide plugin commands.
# 
# To use this PluginManager, add `require "path/to/PluginManager.rb"` to the
# Scripts Editor. There can not be any non-ASCII characters in the game path.
# 
# Then, enable your plugins at the beginning or press F11 in game.
# TODO: There should be standalone GUI/CLI to help manage scripts.
# 
# To use the "features" of PluginManager, do these:
# - Add "# @xxx yyy" comments in the script file, valid tags are:
#   @title        Optional    default: File.basename
#   @plugindesc   Optional
#   @author       Optional
#   @param, @desc, @type, @default    see below.
#   @help         Optional
#   @mod          Optional            see below.
# - Use `PluginManager.parameters('plugin title')` to get a Hash of params,
#   which will be like: { 'PATH' => '' }
#   The keys are always String, values are converted as @type indicate.
#   @type is 'string' by default so it becomes "". Valid types are:
#   string (''), int (0), float (0), bool (false), eval (nil).
# - Use `PluginManager.uninstall('plugin title') { ... }` to do extra works
#   when uninstalling a plugin.
# - Use @mod tag to omit the uninstall block. Here is how it works:
#   Before installing, the plugin manager will save the old methods as @mod
#   indicated. After uninstallation, the plugin manager will restore the
#   old methods just like they aren't modified.
# - By design, a plugin can be uninstalled only if it sets 'uninstall' block
#   or uses @mod tags.
# - Use comments in events to run plugin commands.
module PluginManager
  PATH = [File.dirname(__FILE__)]

  Parameters = {}
  Parameters[to_s]                = {}
  Parameters[to_s]['PATH']        = ''
  Parameters[to_s]['Config File'] = './Plugins.ini'

  Plugins = []

  def self.uninstall(title, &block)
    Plugins.find { |it| it.title == title }.uninstall(&block)
  end

  def self.enabled?(title)
    Parameters.key? title
  end

  def self.enable(title)
    Parameters[title] ||= {}
  end

  def self.disable(title)
    Parameters.delete(title)
  end

  def self.toggle(title)
    enabled?(title) ? disable(title) : enable(title)
  end

  def self.parameters(title)
    Parameters[title] || {}
  end

  def self.config_file
    Parameters[to_s]['Config File'].tap { |it| touch it }
  end

  def self.paths
    smuggle = File.dirname(__FILE__)
    results = Parameters[to_s]['PATH'].split(';') + [smuggle]
    results.uniq
  end

  def self.touch(file)
    open(file, 'w') {} unless File.exist?(file)
  end

  def self.read_ini(file)
    return {} unless File.file?(file)
    sctn = 'root'
    rslt = {}
    File.readlines(file, chomp: true).each do |line|
      line = line.strip
      if n = line.index(';')
        line = line[0, n]
      end
      next if line.empty?
      if line.start_with?('[') and n = line.index(']')
        sctn = line[1, n - 1]
        rslt[sctn] ||= {}
      else
        k, v = line.split('=', 2)
        rslt[sctn][k] = v if k and v
      end
    end
    rslt
  end

  def self.write_ini(file, data)
    ini = []
    data.each do |section, pairs|
      ini << "[#{section}]"
      pairs.each do |k, v|
        ini << "#{k}=#{v}"
      end
      ini << ''
    end
    open(file, 'w') { |f| f.puts ini }
  end

  def self.load_config(config)
    config.each do |title, params|
      Parameters[title] ||= {}
      Parameters[title].merge! params
    end
  end

  def self.save_config
    write_ini config_file, Parameters
  end

  def self.search_plugins(path)
    Dir.glob(File.join(path, '*.rb'))
  end

  class << ::SceneManager
    alias run_without_plugin_manager run
    def run
      PluginManager.init
      run_without_plugin_manager
    end
  end

  class Plugin
    attr_reader :path

    def initialize(file)
      @path = file
      parse_tags
      @mods = []
      @uninstall = nil
    end

    def enabled?
      PluginManager.enabled? title
    end

    def uninstall(&block)
      @uninstall = block
    end

    def reloadable?
      return false if @path == __FILE__
      @uninstall || !@tags['mods'].empty?
    end

    def sign
      a = enabled?
      b = reloadable?
      case
      when  a &&  b then '+'
      when  a && !b then '*'
      when !a &&  b then '-'
      else               ' '
      end
    end

    def title
      @tags['title'] || File.basename(@path, '.rb')
    end

    def plugindesc
      @tags['plugindesc'] || ''
    end
    alias desc plugindesc

    def author
      @tags['author'] || ''
    end

    def help
      @tags['help'] || ''
    end

    def inspect
      "#<Plugin #{title}: #{desc}>"
    end
    alias to_s inspect

    def update
      if enabled? and reloadable? and @_mtime != File.mtime(@path)
        puts "reload #{inspect}"
        reload!
        @_mtime = File.mtime(@path)
      end
    end

    def uninstall
      @uninstall.call if @uninstall
      @mods.each do |klass, nevv, old|
        klass.class_eval { alias_method old, nevv; remove_method nevv }
      end.clear
    end

    def install
      uid = rand 32768
      @tags['mods'].each do |name|
        klass     = 'Object'
        meth      = nil
        singleton = false
        if name.include?('.') || name.include?('::')
          singleton = true
          klass, meth = name.split(/\.|::/, 2)
        elsif name.include?('#')
          klass, meth = name.split(/#/, 2)
        else
          meth = name
        end
        klass = eval(klass)
        klass = klass.singleton_class if singleton
        nevv = "_#{meth}_#{uid += 1}"
        klass.class_eval do
          alias_method nevv, meth
        end
        @mods << [klass, nevv, meth]
      end
      load @path
    end

    def reload!
      parse_tags
      uninstall
      install
    end

    def parse_tags
      @tags = { 'params' => {}, 'mods' => [] }
      _tag = _para = nil
      File.readlines(@path, chomp: true).each do |line|
        if line.slice!(/^\s*#\s?/)
          if line.start_with?('@')
            _tag = line.slice!(/^@\w+/)[/\w+/]
            _val = line.strip
            case _tag
            when 'param'
              @tags['params'][(_para = _val)] = {
                'desc' => '',
                'type' => 'string',
                'default' => ''
              }
            when 'desc', 'type', 'default'
              @tags['params'][_para][_tag] = _val
            when 'mod'
              @tags['mods'] << _val
            else
              _para = nil
              @tags[_tag] = _val
            end
          elsif long_tag?(_tag)
            if _para
              @tags['params'][_para][_tag] += line
            else
              @tags[_tag] += line
            end
          else
            _tag = _para = nil
          end
        end
      end
    end

    def long_tag?(tag)
      tag and (tag.include?('desc') or tag.include?('help'))
    end
  end

  UI_COLORS = {
    '+' => Color.new(0, 255, 0),
    '-' => Color.new(255, 255, 255),
    '*' => Color.new(0, 0, 255),
    ' ' => Color.new(255, 255, 255, 160)
  }
  def self.ui_enable_plugins
    index  = 0
    sprite = Sprite.new
    size   = Plugins.size
    canvas = Bitmap.new Graphics.width, size * 32
    canvas.font.name = ['SimHei']
    canvas.font.size = 20
    refresh = lambda do
      canvas.clear
      Plugins.each_with_index do |plugin, i|
        color = UI_COLORS[plugin.sign]
        if index == i
          canvas.fill_rect 0, 32 * i, Graphics.width, 32, color
          canvas.clear_rect 1, 32 * i + 1, Graphics.width - 2, 32 - 2
        end
        canvas.font.color = color
        canvas.draw_text 8, 32 * i, Graphics.width - 8, 32, plugin.title
      end
    end
    sprite.bitmap = canvas
    _index = -1
    loop do
      Input.update
      index -= 1 if Input.repeat? :UP
      index += 1 if Input.repeat? :DOWN
      index %= size
      refresh.call if _index != index
      if Input.trigger? :C and Plugins[index].sign != '*'
        PluginManager.toggle Plugins[index].title
        refresh.call
      elsif Input.trigger? :B
        break
      end
      Graphics.update
    end
  end

  def self.init
    Plugins.clear
    load_config read_ini config_file
    files = paths.flat_map { |path| search_plugins path }
    files.each { |file| Plugins << Plugin.new(file) }
    ui_enable_plugins
    Plugins.each { |plugin| plugin.install if plugin.sign == '+' }
    save_config
    display
  end

  def self.display
    puts "==> Plugins"
    Plugins.each do |plugin|
      puts " [#{plugin.sign}] #{plugin}"
    end
  end

  def self.update
    Plugins.each(&:update)
  end

  class << Graphics
    alias update_without_plugin_manager update
    def update
      PluginManager.update
      update_without_plugin_manager
    end
  end
end
# TODO: So far, I realized that RPG Maker is able to write GUI programs
#       running ruby(rgss). todo: module UI