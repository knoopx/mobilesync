require 'fusefs'

# CREDIT: https://raw.github.com/lwoggardner/rfusefs/master/lib/fusefs/pathmapper.rb
module MobileSync
  # A FuseFS that maps files from files from their original location into a new path
  # eg tagged audio files can be mapped by title etc...
  class VirtualFilesystem < FuseFS::FuseDir

    # Convert raw_mode strings to IO open mode strings
    def self.open_mode(raw_mode)
      case raw_mode
        when "r"
          "r"
        when "ra"
          "r" #not really sensible..
        when "rw"
          "w+"
        when "rwa"
          "a+"
        when
        "w"
        when "wa"
          "a"
      end
    end

    attr_accessor :use_raw_file_access, :allow_write

    #Creates a self
    #See #map_directory
    def self.create(dir, options={}, &block)
      pm_fs = VirtualFilesystem.new(options)
      pm_fs.map_directory(dir) do |file|
        block.call(file)
      end
      return pm_fs
    end

    def initialize(options = {})
      @root = {}
      @use_raw_file_access = options[:use_raw_file_access]
      @allow_write = options[:allow_write]
    end

    # Adds new_path to our list of mapped files
    #
    # Returns a hash entry which stores the real_path under the :pm_real_path key.
    def map_file(real_path, new_path)
      #split path into components
      components = new_path.scan(/[^\/]+/)

      #create a hash of hashes to represent our directory structure
      new_file = components.inject(@root) { |directory, file|
        directory[file] ||= Hash.new()
      }
      new_file[:pm_real_path] = real_path
      return new_file
    end

    # Convenience method to recursively map all files according to the given block
    def map_directory(*dirs)
      require 'find'
      Find.find(*dirs) do |file|
        new_path = yield file
        map_file(file, new_path) if new_path
      end
    end

    # Takes a mapped file name and returns the original real_path
    def unmap(path)
      possible_file = node(path)
      return possible_file ? possible_file[:pm_real_path] : nil
    end

    # Returns true for any directory referenced by a mapped file
    # See FuseFS API.txt
    def directory?(path)
      possible_dir = node(path)
      possible_dir && !possible_dir[:pm_real_path]
    end

    # See FuseFS API.txt
    # expects to be called only if directory? returns true
    def contents(path)
      node(path).keys
    end

    # See FuseFS API.txt
    def file?(path)
      filename = unmap(path)
      filename && File.file?(filename)
    end

    # See FuseFS API.txt
    # only called if option :raw_reads is not set
    def read_file(path)
      IO.read(unmap(path))
    end

    # We can only write to existing files
    # because otherwise we don't have anything to back it
    def can_write?(path)
      @allow_write && file?(path)
    end

    def write_to(path, contents)
      File.open(path) do |f|
        f.print(contents)
      end
    end

    # See FuseFS API.txt
    def size(path)
      File.size(unmap(path))
    end

    # See RFuseFS API.txt
    def times(path)
      realpath = unmap(path)
      if (realpath)
        stat = File.stat(realpath)
        return [stat.atime, stat.mtime, stat.ctime]
      else
        # We're a directory
        return [0, 0, 0]
      end
    end

    # See FuseFS API.txt
    # Will create, store and return a File object for the underlying file
    # for subsequent use with the raw_read/raw_close methods
    # expects file? to return true before this method is called
    def raw_open(path, mode, rfusefs = nil)

      return false unless @use_raw_file_access

      return false if mode.include?("w") && (!@allow_writes)

      @openfiles ||= Hash.new() unless rfusefs

      real_path = unmap(path)

      unless real_path
        if rfusefs
          raise Errno::ENOENT.new(path)
        else
          #fusefs will go on to call file?
          return false
        end
      end

      file = File.new(real_path, VirtualFilesystem.open_mode(mode))

      @openfiles[path] = file unless rfusefs

      return file
    end

    # See (R)FuseFS API.txt
    def raw_read(path, off, sz, file=nil)
      file = @openfiles[path] unless file
      file.sysseek(off)
      file.sysread(sz)
    end

    # See (R)FuseFS API.txt
    def raw_write(path, offset, sz, buf, file=nil)
      file = @openfiles[path] unless file
      file.sysseek(off)
      file.syswrite(buf[0, sz])
    end

    # See (R)FuseFS API.txt
    def raw_close(path, file=nil)
      unless file
        file = @openfiles.delete(path)
      end
      file.close if file
    end

    private
    # returns a hash representing a given node, if we have a mapped entry for it, nil otherwise
    # this entry is a file if it has_key?(:pm_real_path), otherwise it is a directory.
    def node(path)
      path_components = scan_path(path)

      #not actually injecting anything here, we're just following the hash of hashes...
      path_components.inject(@root) { |dir, file|
        break unless dir[file]
        dir[file]
      }
    end
  end
end

