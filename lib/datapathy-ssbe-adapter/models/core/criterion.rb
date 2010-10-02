
class Criterion < SsbeModel
  service_type :measurements

  persists :target, :comparison, :pattern

  validates_presence_of :target, :comparison
  validates_presence_of :pattern, :message => "Pattern is required"
  validate :comparison_valid_for_target

  def valid_comparisons
    MetricFilter.targets.detect { |comparisons|
      comparisons["target"] == target
    }["valid_comparisons"]
  end

  def new_record?; false; end
  def persisted?;  false;  end

  protected

  def comparison_valid_for_target
    unless valid_comparisons.include?(comparison)
      errors.add(:comparison, "Comparison is applicable to this target")
    end
  end

end
