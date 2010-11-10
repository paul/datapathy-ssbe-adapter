class Client < SsbeModel
  include AccessControl

  service_type :kernel
  resource_name :AllClients

  persists :name, :longname, :active, :parent_href, :hosts_href

  def hosts
    Host.from(hosts_href)
  end

  def client
    self
  end

  def self.by_href(href, reload = nil)
    @cache = nil if reload
    @cache ||= all.to_a.map { |a| [a.href, a] }.inject({}){ |ha, (k,v)| ha[k] = v; ha }

    @cache[href]
  end

end
