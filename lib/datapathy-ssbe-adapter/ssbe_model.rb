require 'addressable/template'
require 'active_support/concern'
require 'datapathy-ssbe-adapter/access_control'

class SsbeModel
  include Datapathy::Model
  include AccessControl

  def self.inherited(model)
    model.persists :_type, :href, :id, :created_at, :updated_at
  end

  def initialize(attributes = {})
    super
    self._type = self.class.to_s
  end

  def save!
    save
  end

  def to_sql(formatter = nil)
    href.to_sql(formatter)
  end

  class << self

    def service_type(service_type = nil)
      if service_type
        @service_type = service_type
      else
        @service_type
      end
    end

    def resource_name(resource_name = nil)
      if resource_name
        @resource_name = resource_name
      else
        @resource_name
      end
    end

    def at(href)
      self[href]
    end

    # Get a collection from a location other than the default
    def from(href, mappings = {})
      query = SsbeQuery.new(model)
      query.location = Addressable::Template.new(href).expand(mappings.stringify_keys).to_str
      Datapathy::Collection.new(query)
    end

    def key
      :href
    end

    def primary_key
      self.key
    end

    def adapter
      Datapathy.adapters[:ssbe]
    end

  end

end

class SsbeQuery < Datapathy::Query
  def location
    @location
  end
  def location=(href)
    @location = href
  end
end
