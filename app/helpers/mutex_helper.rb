module MutexHelper
  def get_lock_key(name, id)
    "#{name}_lock_#{id}"
  end

  def lock_exists(name, id)
    Rails.cache.exist? get_lock_key(name, id)
  end

  def create_lock(name, id, expires = 1.month)
    Rails.cache.write(get_lock_key(name, id), Time.zone.now.getutc, expires_in: expires)
  end

  def remove_lock(name, id)
    Rails.cache.delete(get_lock_key(name, id))
  end
end
