
class MetricFilter < SsbeModel
  service_type  :measurements
  resource_name :AllMetricFilters

  persists :purpose, :any_or_all, :criteria, :criteria_href, :client_href, :metrics_href

  validates_presence_of :client_href
  validates_presence_of :purpose, :any_or_all
  validates_inclusion_of :any_or_all, :in => ["any", "all"]
  validate :valid_criteria

  def client=(client)
    self.client_href = client.href
  end

  def client
    @client ||= Client.at(client_href) if client_href
  end

  def any?
    any_or_all == "any"
  end

  def all?
    !any?
  end

  def criteria
    persisted_attributes[:criteria] ||= []
    if persisted_attributes[:criteria].first.is_a?(Hash)
      persisted_attributes[:criteria].map!{ |c| Criterion.new(c) }
    end
    persisted_attributes[:criteria]
  end

  def criteria_attributes=(attributes)
    criteria = []
    attributes.each do |i, values|
      next if values[:_delete] && values[:_delete].to_i == 1
      criteria << Criterion.new(values.merge(:id => i))
    end

    self.criteria = criteria
  end

  def self.targets
    @targets ||= JSON.parse(targets_json).with_indifferent_access[:items]
  end

  def self.targets_json
    url = ServiceDescriptor[:measurements].resource_for("AllMetricFilterTargets").href
    response = adapter.http.resource(url).get(:accept => ServiceDescriptor::ServiceIdentifiers[:measurements].mime_type)
    response.body
  end

  protected

  def valid_criteria
    criteria.each do |c|
      errors.add(:criteria, :invalid) unless c.valid?
    end
  end


end
