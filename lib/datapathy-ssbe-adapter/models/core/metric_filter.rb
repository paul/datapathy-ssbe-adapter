
class MetricFilter < SsbeModel
  service_type  :measurements
  resource_name :AllMetricFilters

  persists :purpose, :any_or_all, :criteria, :client_href, :metrics_href

  validates_presence_of :client_href
  validates_presence_of :purpose, :any_or_all
  validates_inclusion_of :any_or_all, :in => ["any", "all"]

  validates_presence_of :criteria
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

  protected

  def valid_criteria
    criteria.each do |c|
      errors.add(:criteria, :invalid) unless c.valid?
    end
  end

  def self.targets_json
    url = ServiceDescriptor[:measurements].resource_for("AllMetricFilterTargets").href
    response = adapter.http.resource(url).get(:accept => ServiceDescriptor::ServiceIdentifiers[:measurements].mime_type)
    response.body
  end

  class Criterion
    include ActiveModel::Validations

    attr_accessor :id, :target, :comparison, :pattern

    attr_accessor :_delete # Virtual attribute for form remove

    validates_presence_of :target,
                          :comparison,
                          :pattern,
                          :message => "is required"
    validate :comparison_valid_for_target

    def initialize(attrs = {})
      attrs.each do |k,v|
        send(:"#{k}=", v)
      end
    end

    def to_json
      {
        :target => target,
        :comparison => comparison,
        :pattern => pattern
      }.to_json
    end

    def valid_comparisons
      MetricFilter.targets.detect { |comparisons|
        comparisons["target"] == target
      }["valid_comparisons"]
    end

    def human_target
      HUMAN_TARGETS[target]
    end

    def human_comparison
      comparison.titlecase
    end

    def new_record?; false; end
    def persisted?;  false;  end

    protected

    def comparison_valid_for_target
      if !target.blank? && !valid_comparisons.include?(comparison)
        errors.add(:comparison, "\"#{human_comparison}\" is not valid for #{human_target}")
      end
    end

    HUMAN_TARGETS = {}.tap do |targets|
      MetricFilter.targets.each { |target|
        targets[target[:target]] = target[:name].split('(').first
      }
    end

  end

end
