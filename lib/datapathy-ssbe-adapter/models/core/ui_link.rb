class UiLink < SsbeModel
  service_type :kernel
  resource_name :AllUiLinks

  persists :category, :title, :target, :id

  def self.[](title)
    self.detect { |l| l.title == title }
  end

  class << self

    def const_missing(name)
      if link = self.detect { |l| l.title == name.to_s }
        const_set(name, link)
      elsif ! (links = self.select { |l| l.category == name.to_s.downcase }).empty?
        const_set(name, links.sort_by { |l| l.title })
      else
        # No uilinks found with title "name" or in category "name"
        []
      end
    end

  end

end
