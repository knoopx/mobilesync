require 'mobilesync/backup'

module MobileSync
  class CLI < Thor
    desc "mount [BACKUP DIR] [MOUNT POINT]", "Mount the specified backup into the specified mount point"

    def mount(backup_path, mount_point)
      backup = Backup.new(backup_path)
      backup.mount(mount_point)
    end
  end
end