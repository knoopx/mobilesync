require 'bindata'
require 'digest'
require 'fusefs'
require 'active_support/core_ext'
require 'mobilesync/virtual_filesystem'

module MobileSync
  class Backup
    class Attribute < BinData::Primitive
      endian :big
      uint16 :len
      string :data, :read_length => lambda { len == 0xffff ? 0 : len }

      def get
        self.data
      end
    end

    class Property < BinData::Primitive
      attribute :property_key
      attribute :property_value

      def get
        {self.property_key => self.property_value}
      end
    end

    class PropertyList < BinData::Primitive
      uint8 :property_count
      array :properties, :initial_length => :property_count, :type => :property

      def get
        self.properties
      end
    end

    class Record < BinData::Record
      endian :big
      attribute :domain
      attribute :path
      attribute :link_target
      attribute :digest
      attribute :dummy1
      uint16 :mode
      uint32 :dummy2
      uint32 :dummy3
      uint32 :user
      uint32 :group
      uint32 :mtime #Time.at
      uint32 :atime #Time.at
      uint32 :ctime #Time.at
      uint64 :file_size
      uint8 :flag
      property_list :properties

      def directory?
        self.file_size == 0 and (self.mode & 040000 > 0)
      end

      def file?
        not directory?
      end
    end

    class Index < BinData::Record
      endian :big
      string :magic, :length => 6
      array :records, :type => :record, :read_until => :eof
    end

    attr_accessor :path, :index

    def initialize(path)
      @path = path
      @index = Index.read(File.open(File.join(path, "Manifest.mbdb")))
    end

    def mount(mount_point)
      filesystem = VirtualFilesystem.new(:use_raw_file_access => true, :allow_write => false)

      index.records.each do |record|
        next if record.directory?
        digest = Digest::SHA1.hexdigest([record.domain, record.path].join("-"))
        real_path = File.join(@path, digest)
        filesystem.map_file(real_path, File.join(File::SEPARATOR, record.path))
      end

      FuseFS.set_root(filesystem)
      FuseFS.mount_under mount_point
      FuseFS.run
    end
  end
end