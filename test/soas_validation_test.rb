# frozen_string_literal: true

require "minitest/autorun"
require "set"
require_relative "../tools/validate_soas"

class SOASValidationTest < Minitest::Test
  def test_complete_repository_contracts
    result = SOASValidation.run
    assert result.success?, result.errors.join("\n")
    assert_equal 72, result.facts[:capability_files]
    assert_equal 72, result.facts[:unique_capability_ids]
    assert_equal 72, result.facts[:unique_objective_sets]
    assert_equal 72, result.facts[:unique_test_recipe_sets]
    assert_operator result.facts[:selection_fixtures], :>=, 8
    assert_operator result.facts[:assurance_fixtures], :>=, 9
  end

  def test_insufficient_evidence_is_not_a_positive_outcome
    refute_includes %w[satisfied finding-raised], "insufficient-evidence"
    assert_includes SOASValidation::OUTCOMES, "insufficient-evidence"
  end

  def test_closed_finding_without_closure_evidence_is_invalid
    schema = JSON.parse(SOASValidation::PACKAGE.join("schemas/finding.schema.json").read)
    finding = JSON.parse(SOASValidation::PACKAGE.join("examples/findings/closed.json").read)
    finding["verification"].delete("regression_evidence")
    refute_empty SOASValidation.schema_errors(finding, schema)
  end

  def test_output_cross_reference_failures_are_detected
    bundle = SOASValidation.load_yaml(SOASValidation::ROOT.join("test/fixtures/outputs/consistent-bundle.yaml"))
    bundle["evidence_ids"].delete("E-1004-regression")
    refute_empty SOASValidation.output_bundle_errors(bundle)
  end

  def test_finalized_execution_requires_complete_output_inventory
    schema = JSON.parse(SOASValidation::PACKAGE.join("schemas/execution.schema.json").read)
    execution = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("templates/plans/execution.yaml"))
    execution["state"] = "finalized"
    execution["completed_at"] = "2026-07-23T01:00:00Z"
    execution["outcome"] = "satisfied"
    execution["outputs"] = {"summary_report" => "summary.md"}
    refute_empty SOASValidation.schema_errors(execution, schema)
  end
end
